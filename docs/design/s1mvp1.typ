#import "../template/project-kit.typ": *

#show: project-document.with(
  title: "算力容器平台第一批 MVP 设计",
  subtitle: "CPU 工作区生命周期、RBAC、数据模型与可扩展接口",
  doc-type: "MVP DESIGN SPECIFICATION",
  version: "V1.0",
  date: "2026-07-22",
  organization: "项目组",
  owner: "冶秉礼",
  status: "内部评审稿",
  toc: true,
)

= 执行摘要

本设计从《异构算力容器教学服务平台设计方案》中收敛首批可交付能力。MVP 的唯一运行时目标是 *CPU 算力容器工作区*：用户在获得授权后可创建、启动、停止、重置和删除自己的工作区；平台保存其状态、资源配额与持久化数据绑定，并通过一个可替换的运行时适配器执行实际容器操作。

首批不建设 NPU/GPU 调度、多集群、课程实验发布、镜像构建、终端协助、对象存储、检查点和公网服务暴露。它们的概念边界和接口扩展点会被预留，但不进入本批数据库迁移、API 承诺或验收范围。

#metric-grid((
  metric-card([首批范围], [CPU 工作区], detail: [创建、启动、停止、重置、删除], tone: "teal"),
  metric-card([核心领域], [3 个], detail: [Identity、Authorization、Workspace], tone: "blue"),
  metric-card([交付目标], [闭环可用], detail: [可审计、可恢复、可替换运行时], tone: "green"),
))

#v(8pt)
#callout(
  [MVP 成功标准],
  [一个拥有 workspace:user 权限的用户能在 3 分钟内创建 CPU 工作区；停止后计算资源释放、数据卷保留；重试不会创建重复资源；未经授权的用户既不能读取状态，也不能执行生命周期操作。],
  tone: "teal",
)

目标、边界与决策

目标

- 建立统一用户、角色、权限和资源归属模型。
- 提供 CPU 工作区从申请到删除的完整状态机与幂等命令处理。
- 建立 PostgreSQL 持久化模型、审计记录与可恢复的异步执行机制。
- 将容器运行时封装在接口之后，首期可以对接单一 Kubernetes 集群或 Docker 实现。
- 以稳定的 REST API 和事件契约支持后续接入课程、异构算力、终端和镜像服务。

明确范围

#data-table(
  ([类别], [纳入 MVP], [不纳入 MVP]),
  (
    ([身份], [OIDC 登录映射、本地用户、角色与权限], [组织同步、临时身份合并、细粒度 ABAC]),
    ([工作区], [CPU 容器创建、启动、停止、重置、删除、状态查询], [NPU/GPU、快照恢复、多人共享、教师观察]),
    ([存储], [每工作区一个持久数据卷、删除策略], [对象存储、课程 Demo、备份与 CSI Snapshot]),
    ([运行时], [一个 CPU 执行池、容器和数据卷编排], [多集群 Broker、租约、设备插件与硬件自检]),
    ([镜像], [仅允许平台配置的白名单镜像], [Dockerfile 构建、扫描、SBOM、Harbor 审批]),
    ([接口], [REST、OpenAPI、审计事件、运行时 SPI], [公开 Webhook、外部开发者生态]),
  ),
  columns: (23mm, 1fr, 1fr),
)

架构决策

#data-table(
  ([编号], [决策事项], [结论], [理由], [状态]),
  (
    ([ADR-M01], [部署形态], [模块化单体 + 独立 Worker], [首期降低交付和运维复杂度；异步任务不阻塞 API。], [已接受]),
    ([ADR-M02], [数据存储], [PostgreSQL + Transactional Outbox], [工作区状态与命令可靠落库，运行时调用可重试。], [已接受]),
    ([ADR-M03], [授权], [RBAC + 资源归属校验], [角色解决“能否做”，归属解决“能对谁做”。], [已接受]),
    ([ADR-M04], [运行时], [WorkspaceRuntime 接口], [隔离 Kubernetes / Docker 对象，为多集群与异构适配留出口。], [已接受]),
    ([ADR-M05], [镜像], [镜像目录白名单], [在没有构建治理前避免任意镜像进入执行环境。], [已接受]),
  ),
  columns: (17mm, 25mm, 38mm, 1fr, 20mm),
  compact: true,
)

业务模型与权限模型

角色与权限

角色是全局或项目范围的授权集合；首批不引入课程，`scope_type` 预留为 `platform` 和 `project` 两种。一个用户可以具有多个角色，最终权限取并集。

#data-table(
  ([角色], [主要权限], [边界]),
  (
    ([platform:admin], [用户、角色、镜像目录、项目和所有工作区管理], [仅运维人员；所有高危操作审计]),
    ([project:owner], [管理本项目成员；查看和操作项目内全部工作区], [不可修改平台级角色和镜像目录]),
    ([workspace:user], [创建、查看、启动、停止、重置、删除本人工作区], [仅限本人资源及项目配额]),
    ([workspace:viewer], [查看被授权项目中的工作区元数据和状态], [不能读取数据、终端或执行操作]),
    ([workspace:operator], [按项目范围执行启动、停止、重置], [不能改变成员、角色和镜像白名单]),
  ),
  columns: (32mm, 1fr, 1fr),
)

权限采用 `resource:action` 命名，例如 `workspace:create`、`workspace:read`、`workspace:start`、`workspace:stop`、`workspace:reset`、`workspace:delete`、`project:member:manage` 和 `image:catalog:read`。

授权判定

每次请求按以下顺序判定：

1. 验证 Access Token 并得到稳定的 `subject`。
2. 读取用户在平台或目标项目的有效角色和权限。
3. 判断请求操作所需权限；创建时检查目标项目范围。
4. 对已有工作区执行资源归属检查：资源所有者、项目成员或平台管理员必须满足其一。
5. 记录允许的高风险操作及全部拒绝操作。

#callout(
  [重要约束],
  [RBAC 不能替代资源归属检查。即使两个用户都具有 workspace:user，A 也不能读取或停止 B 的工作区。项目 Owner/Operator 的跨用户操作必须同时携带目标项目范围，并写入审计日志。],
  tone: "warning",
)

总体架构

组件关系

#block(fill: colors.panel, stroke: 0.5pt + colors.border, radius: 5pt, inset: 10pt)[
  #grid(
    columns: (1fr, 10mm, 1fr, 10mm, 1fr),
    row-gutter: 10pt,
    align: center + horizon,
    architecture-node([Web / CLI], [OIDC 登录、工作区操作、状态展示], tone: "blue"),
    flow-arrow(),
    architecture-node([API 模块], [认证、RBAC、Workspace Application Service], tone: "teal"),
    flow-arrow(),
    architecture-node([PostgreSQL], [业务数据、Outbox、审计、幂等记录], tone: "green"),

    architecture-node([OIDC Provider], [签发 Access Token、用户声明], tone: "purple"),
    flow-arrow(),
    architecture-node([Worker], [领取 Outbox 命令、重试与对账], tone: "amber"),
    flow-arrow(),
    architecture-node([CPU Runtime Adapter], [Kubernetes 或 Docker 容器/卷操作], tone: "red"),
  )
]

模块边界

#data-table(
  ([模块], [职责], [不得依赖]),
  (
    ([Identity], [OIDC subject 映射、本地用户状态], [工作区状态机、Kubernetes SDK]),
    ([Authorization], [角色、权限、范围和策略判定], [Pod、Volume 等基础设施对象]),
    ([Project], [项目、成员关系、配额], [运行时实现细节]),
    ([Workspace], [聚合、状态机、命令、镜像与数据卷绑定], [Kubernetes/Docker 类型]),
    ([Runtime Adapter], [将期望状态转换为容器运行操作], [HTTP 请求与 RBAC 查询]),
    ([Audit/Outbox], [可靠事件、审计记录、重试与死信处理], [领域规则决策]),
  ),
  columns: (31mm, 1fr, 1fr),
)

CPU 工作区生命周期

聚合与状态机

`Workspace` 是首批核心聚合，保存期望状态、实际状态、代次（generation）、数据卷引用和最后一次运行时操作信息。任何改变运行时状态的命令均增加 `generation`；Worker 仅能提交与当前 generation 匹配的结果，从而避免旧任务覆盖新命令。

```text
Requested -> Provisioning -> Running -> Stopping -> Stopped
                 |               |          |          |
                 v               v          v          v
               Failed <------- Resetting <-+        Deleting -> Deleted

Stopped -> Starting -> Running
Failed  -> Starting | Resetting | Deleting
```

#data-table(
  ([命令], [允许来源状态], [运行时动作], [成功后状态]),
  (
    ([Create], [无], [创建数据卷与 CPU 容器], [Running 或 Failed]),
    ([Start], [Stopped、Failed], [确保卷存在并启动容器], [Running 或 Failed]),
    ([Stop], [Running、Provisioning], [优雅终止容器，保留数据卷], [Stopped 或 Failed]),
    ([Reset], [Running、Stopped、Failed], [删除容器并以镜像重建；保留数据卷], [Running 或 Failed]),
    ([Delete], [非 Deleted], [删除容器；按策略删除或保留数据卷], [Deleted 或 Failed]),
  ),
  columns: (22mm, 38mm, 1fr, 28mm),
)

`Reset` 不等于“清空用户数据”。首批默认只重建容器；若以后引入课程文件或快照，再通过显式的 `ResetMode` 扩展为文件重置和检查点恢复。

幂等与并发控制

- 所有变更 API 必须接收 `Idempotency-Key`，服务端在同一调用者和路由范围内保存请求摘要与响应 24 小时。
- `workspaces.version` 使用乐观锁。版本不匹配时返回 `409 Conflict`，客户端重新读取后再决定是否发起操作。
- 同一工作区一次只允许一个未完成的生命周期命令；新命令返回 `409 workspace_operation_in_progress`，而不隐式覆盖。
- Worker 对运行时操作使用 `workspace_id + generation + operation` 作为幂等键，并周期性对账实际容器状态。

资源与默认配置

首批 `CpuWorkspaceProfile` 是配置表中的不可变版本，不接受用户自定义 CPU、内存或镜像。推荐仅提供 `small`（1 CPU / 2 GiB）和 `standard`（2 CPU / 4 GiB）两个档位。项目同时限制最大工作区数量、总 CPU、总内存和存储容量。

数据库设计

关系概览

```text
users --< role_bindings >-- roles --< role_permissions >-- permissions
  |
  +--< project_members >-- projects --< workspace_profiles
  |                                  |
  +--< workspaces --< workspace_operations
  |       |                |
  |       |                +-- outbox_events
  |       +-- audit_logs
  |
  +-- idempotency_records
```

核心表

#data-table(
  ([表], [关键字段], [说明]),
  (
    ([users], [id, oidc_subject, display_name, status], [稳定内部 ID 与外部 OIDC subject 一对一；禁止直接以邮箱作主键]),
    ([projects], [id, slug, name, status, cpu_quota, memory_quota], [工作区归属与配额边界]),
    ([project_members], [project_id, user_id, role], [项目成员与项目范围角色]),
    ([roles / permissions], [id, code / id, code], [全局权限目录及角色授权集合]),
    ([role_bindings], [subject_type, subject_id, role_id, scope_type, scope_id], [全局或项目范围角色绑定]),
    ([workspace_profiles], [id, project_id, name, image_ref, cpu_millicores, memory_bytes], [管理员管理的 CPU 配置版本]),
    ([workspaces], [id, project_id, owner_id, profile_id, status, generation, version], [工作区聚合快照]),
    ([workspace_operations], [id, workspace_id, operation, generation, status, idempotency_key], [可重试的异步生命周期命令]),
    ([outbox_events], [id, aggregate_type, aggregate_id, event_type, payload, status], [事务内写入、Worker 异步投递]),
    ([audit_logs], [id, actor_id, action, resource_type, resource_id, result, occurred_at], [允许、拒绝及管理员操作审计]),
  ),
  columns: (34mm, 1fr, 1fr),
  compact: true,
)

关键 DDL 草案

```sql
create table workspaces (
  id uuid primary key,
  project_id uuid not null references projects(id),
  owner_id uuid not null references users(id),
  profile_id uuid not null references workspace_profiles(id),
  name varchar(63) not null,
  status varchar(24) not null,
  desired_state varchar(24) not null,
  generation integer not null default 1,
  version integer not null default 1,
  runtime_ref varchar(255),
  volume_ref varchar(255),
  delete_volume boolean not null default false,
  failure_code varchar(64),
  failure_message text,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  unique (project_id, owner_id, name)
);

create table workspace_operations (
  id uuid primary key,
  workspace_id uuid not null references workspaces(id),
  operation varchar(24) not null,
  generation integer not null,
  status varchar(24) not null,
  idempotency_key varchar(128) not null,
  requested_by uuid not null references users(id),
  error_code varchar(64),
  error_message text,
  created_at timestamptz not null,
  finished_at timestamptz,
  unique (workspace_id, generation),
  unique (requested_by, idempotency_key)
);
```

索引至少包含 `workspaces(project_id, status)`、`workspaces(owner_id, status)`、`workspace_operations(status, created_at)`、`audit_logs(resource_id, occurred_at desc)` 与 `outbox_events(status, created_at)`。所有业务查询必须带项目或所有者条件，不能依赖前端隐藏来隔离数据。

事务边界与 Outbox

创建、启动、停止、重置和删除命令在同一数据库事务中完成：授权确认、聚合状态更新、操作记录创建、审计记录写入和 `WorkspaceOperationRequested` Outbox 事件写入。提交后 Worker 以 `FOR UPDATE SKIP LOCKED` 领取事件，调用 Runtime Adapter，并在新事务中写回结果。

这确保“数据库已显示 Running 但没有执行命令”与“执行命令却没有可追踪记录”都可通过重试或对账恢复；它不承诺对外部运行时的分布式事务。

API 与扩展接口

外部 REST API

#data-table(
  ([接口], [权限], [语义]),
  (
    ([POST /v1/projects], [project:create], [创建项目；仅平台管理员或预配置 Owner]),
    ([GET /v1/projects/{projectId}/workspaces], [workspace:read], [按项目分页查询；结果按归属过滤]),
    ([POST /v1/projects/{projectId}/workspaces], [workspace:create], [创建并异步开通；必须提供 Idempotency-Key]),
    ([GET /v1/workspaces/{workspaceId}], [workspace:read], [读取聚合状态、当前操作和失败原因]),
    ([POST /v1/workspaces/{workspaceId}:start], [workspace:start], [异步启动]),
    ([POST /v1/workspaces/{workspaceId}:stop], [workspace:stop], [异步停止并保留卷]),
    ([POST /v1/workspaces/{workspaceId}:reset], [workspace:reset], [异步重建容器，默认保留卷]),
    ([DELETE /v1/workspaces/{workspaceId}], [workspace:delete], [异步删除；可显式指定 deleteVolume]),
    ([GET /v1/workspaces/{workspaceId}/operations], [workspace:read], [查看操作历史与故障信息]),
  ),
  columns: (70mm, 35mm, 1fr),
  compact: true,
)

创建请求示例：

```json
{
  "name": "lab-01",
  "profileId": "cpu-standard-v1",
  "deleteVolumeOnDelete": false
}
```

成功受理返回 `202 Accepted` 和 `operationId`；客户端使用工作区或操作查询接口轮询。同步 API 不等待容器真的启动，避免控制面被镜像拉取和运行时延迟占用。

运行时 SPI

领域模块只依赖下列接口；Kubernetes、Docker 或未来 Cluster Agent 分别实现它。

```text
interface WorkspaceRuntime {
  ensureVolume(spec: VolumeSpec): RuntimeResult
  ensureWorkspace(spec: RuntimeWorkspaceSpec): RuntimeResult
  stopWorkspace(ref: RuntimeRef): RuntimeResult
  deleteWorkspace(ref: RuntimeRef, deleteVolume: bool): RuntimeResult
  inspectWorkspace(ref: RuntimeRef): RuntimeWorkspaceState
}

RuntimeWorkspaceSpec {
  workspaceId, generation, imageRef, cpuMillicores, memoryBytes,
  environment, volumeRef, labels
}
```

接口输入只携带领域与通用资源概念，不出现 Pod、Namespace、PVC、Docker Container ID 等类型。适配器将 `workspaceId` 和 `generation` 写入运行时标签，供幂等和对账使用。

事件契约

#data-table(
  ([事件], [生产者], [消费者/用途]),
  (
    ([WorkspaceOperationRequested], [Workspace 应用服务], [Worker 领取并调用 Runtime Adapter]),
    ([WorkspaceProvisioned], [Worker], [更新状态；后续可供通知和课程进度订阅]),
    ([WorkspaceStopped], [Worker], [更新状态与资源使用统计]),
    ([WorkspaceOperationFailed], [Worker], [记录失败、告警与人工重试]),
    ([AuthorizationDenied], [Authorization], [安全审计和异常检测]),
  ),
  columns: (52mm, 38mm, 1fr),
)

事件必须具有 `event_id`、`aggregate_id`、`generation`、`occurred_at`、`correlation_id` 和版本化 payload。新增字段只能向后兼容；消费者不得依赖未声明字段。

安全、可靠性与可观测

安全基线

- Access Token 由受信任 OIDC Provider 签发，API 校验签名、issuer、audience、expiry 与撤销策略。
- 工作区容器默认非 root、禁止特权、禁止 hostNetwork/HostPath、使用资源限制并只暴露 CPU 配置。
- 镜像只能来自平台配置的镜像目录及 digest 或受控 tag；用户请求不接收任意 image URL。
- 运行时凭据仅存在于 Worker/Adapter 的受控环境，绝不返回前端或写入业务日志。
- 高风险行为（角色变更、删除工作区、跨用户操作、拒绝访问）必须记录 actor、目标、请求 ID、结果和原因。

失败处理

#data-table(
  ([场景], [处理], [用户可见结果]),
  (
    ([API 重试], [命中 Idempotency-Key 后返回原 operationId], [不会重复创建工作区]),
    ([Worker 崩溃], [Outbox 租约超时后由其他 Worker 重领], [操作短暂 Pending，随后继续]),
    ([运行时短暂失败], [指数退避重试；达到阈值标记 Failed], [查看失败码并由用户或管理员重试]),
    ([数据库与运行时状态不一致], [定期 inspect 与 generation 标签对账], [系统自动修正或生成待处理告警]),
    ([删除卷失败], [工作区保持 Deleting/Failed，禁止重名复用], [管理员可安全重试，不静默丢失数据]),
  ),
  columns: (36mm, 1fr, 1fr),
)

指标与日志

最小指标集：工作区按状态数量、每种操作耗时与失败率、Outbox 队列深度、Worker 重试数、运行时调用延迟、配额使用量、授权拒绝数和 API P95 延迟。每条 API、操作、事件和运行时调用贯穿 `request_id` 与 `correlation_id`。

实施顺序与验收

建议迭代

#data-table(
  ([迭代], [交付], [退出条件]),
  (
    ([M1：身份与数据基线], [PostgreSQL 迁移、OIDC 映射、用户/项目/角色/权限、审计中间件], [Token 校验和项目范围授权集成测试通过]),
    ([M2：工作区领域], [聚合、状态机、幂等、操作记录、Outbox], [并发命令与重复请求测试通过]),
    ([M3：CPU 运行时], [Kubernetes 或 Docker Adapter、Worker、对账、数据卷], [创建/停止/重置/删除完整闭环通过]),
    ([M4：API 与治理], [OpenAPI、限流、指标、告警、管理接口与演练], [验收脚本、审计和故障恢复演练通过]),
  ),
  columns: (37mm, 1fr, 1fr),
)

MVP 验收清单

#checklist((
  (true, [用户可使用 OIDC 登录，且同一 subject 不会创建重复用户。]),
  (true, [项目 Owner 可管理项目成员；普通用户不能读取其他项目或其他用户的工作区。]),
  (true, [CPU 工作区创建、启动、停止、重置、删除均通过异步操作完成，并可查询进度。]),
  (true, [停止或重置后数据卷保持；删除时依据显式策略保留或删除数据卷。]),
  (true, [相同 Idempotency-Key 重试不会创建第二个工作区或第二个操作。]),
  (true, [Worker 或运行时暂时不可用时，命令可重试且不丢失审计记录。]),
  (true, [所有删除、角色变更、跨用户操作和授权拒绝均可按 request_id 查询。]),
  (true, [运行时接口可替换，领域模块不存在 Kubernetes 或 Docker 类型依赖。]),
))

后续扩展路径

本 MVP 完成后，扩展遵循“先增加模型与策略，再增加适配器”的顺序：先引入 `ComputeProfile` 与 `ResourceLease` 支持异构调度；再增加 `LabRelease`、课程 RBAC 与只读课程内容；最后引入 Terminal Gateway、镜像构建、检查点、服务暴露和多集群 Agent。首批 API 的资源 ID、项目范围、事件版本、generation 与 Runtime SPI 均为这些演进保留了兼容位置。

#callout(
  [首批边界结论],
  [MVP 的价值不是模拟完整教学云，而是验证一条可靠的控制面闭环：身份已知、权限正确、状态可追踪、容器可控、数据可保留、失败可恢复。这个闭环稳定后，再以独立领域和适配器扩展异构算力能力。],
  tone: "success",
)
