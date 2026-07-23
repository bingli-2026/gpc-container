# Implementation Plan: 昇腾算子远程实训平台一期 MVP

**Branch**: `001-cpu-workspace-mvp` | **Date**: 2026-07-23 | **Spec**: [spec.md](spec.md)

**Input**: 功能规格、[研究决策](research.md)、[数据模型](data-model.md)、
[控制面契约](contracts/phase1.openapi.yaml)、[验证指南](quickstart.md)、
[总体设计](../../docs/design/overall-design.typ) 与
[一期总体方案](../../docs/design/spec1.typ)。

## Summary

交付受控单节点中的昇腾算子远程实训一期：经统一身份认证且在班级范围内获授权的主体，可使用平台批准、
班级启用的 CPU 或昇腾 NPU Profile 创建和管理持久工作区；可通过 WebIDE、SSH 和 VS Code
Remote-SSH 进入同一环境；教师或授权助教可在本班查看过滤后的终端过程。平台提供可扩展 RBAC、
培训期结束处置、独立任务工作区与基础运营证据。

Go 模块化单体提供权威控制面与 Worker，Next.js 作为 BFF 和呈现层。PostgreSQL 负责控制面事实、
操作、审计与可靠分发；受控单节点 K3s Adapter 在其内部处理 CPU/NPU 运行规格、持久卷和
Ascend device-share。所有外部副作用以持久操作、Outbox、幂等键、generation 与协调恢复执行。

## Technical Context

**Language/Version**: Go 1.26.5；TypeScript / Node.js 24（Next.js BFF）。

**Primary Dependencies**: Go 标准 HTTP 层、OIDC/JWT 验证、PostgreSQL 驱动和迁移工具、
OpenAPI 3.1 契约校验、OpenTelemetry、Prometheus；Next.js App Router、Tailwind CSS v4、
shadcn/ui（Radix UI primitives）与 pnpm；K3s、
受控 Ascend device-share Adapter、共享持久存储与终端采集 Adapter。

**Storage**: PostgreSQL 是权威控制面系统；版本化 SQL 迁移；操作、审计和 Outbox 同一事务。
Workspace Volume 由存储 Adapter 管理，运行时使用受控共享持久存储挂载；终端归档与实时索引均带
班级范围、保留策略和关联信息。

**Testing**: Go 单元、架构、迁移、数据库集成、契约、K3s/Ascend Adapter 集成和故障协调测试；
Next.js 组件/集成测试（断点、键盘、Skeleton 与不可枚举状态）；双班级隔离、三种入口、CPU/NPU、
终端采集、培训期结束与长期任务的端到端验收。

**Target Platform**: 受控 Linux 单节点 K3s；x86 控制节点与 Orange Pi AIPro 8T/20T 运行节点。
一期硬件兼容性验证决定 Adapter 内部映射，不能把设备资源键、注解或设备路径写入公开契约。

**Project Type**: Web 应用（Go 控制面/Worker + Next.js BFF + 受控运行时与采集 Adapter）。

**Performance Goals**: 在环境与资源可用时，20 次 CPU 创建至少 19 次在 3 分钟内到达可用或明确失败；
每个可用 NPU 节点至少可并发 3 个受控 NPU 工作区；状态变更请求在同步预算内持久受理并返回操作标识。

**Constraints**: CPU/NPU 配额、调度资格和统计独立核算；NPU 拒绝不得静默降级至 CPU；工作负载非特权、
非 root、无 HostPath、host network 或运行时 socket；浏览器不直连权威数据库；所有范围外访问不可枚举；
W3C Trace Context、审计、`/healthz` 与 `/readyz` 为必需。前端使用 Tailwind mobile-first 的统一
12 栏栅格，基础交互由共享 shadcn/ui 组件组合，禁止逐页手写。

**Scale/Scope**: 约 30 人受控多班级试点；CPU 与 Ascend NPU Profile；三种访问入口；终端采集；
受控控制面长期任务。排除课程模板、远程接管/回放、评分、镜像构建、vNPU/HAMi、服务发布与多集群。

## Constitution Check

*Pre-Phase 0: PASS. Post-Phase 1: PASS。未记录宪法例外；控制面 OpenAPI 1.3 草案已覆盖前端原型所需
读写模型，前端 UI 契约可冻结。*

- [x] 限界上下文、聚合所有权、不变量和事务边界明确；设备、K3s、NFS 和日志实现均位于 Adapter 后。
- [x] 每项受影响动作规定身份、RBAC、班级/所有权范围、工作负载权限与审计效果。
- [x] 生命周期与任务定义操作 ID、幂等、generation、持久分发、重试、协调和删除/保留恢复。
- [x] API、事件、Adapter 和迁移均使用版本化契约；当前草案未有外部消费者，发布前冻结。
- [x] 单元、集成、契约、端到端、审计、指标、追踪、健康、ADR 与运行证据均有计划交付物。
- [x] 验证入口与 Conventional Commits 已列出；每次提交前必须运行适用验证。
- [x] Go 依赖方向、Next.js BFF、Trace Context 和 CPU/NPU 工作负载隔离均受宪法约束。
- [x] 迁移任务要求锁/语句超时、事务性、兼容窗口、roll-forward 与演练证据。

### Frontend contract-freeze gate

**PASS — `phase1.openapi.yaml` 1.3 草案已定义权限 CRUD、成员移除、Profile/额度治理、异步安全/合规
撤销、强制数据处置的工作区删除、操作/卷、终端筛选、schema 强制的受授权导出下载、Task Grant、
运营摘要和主体能力。** 这些字段只以领域语言表达；前端可使用它们做展示和非权威交互，
但任何资源存在性和授权结论仍由 Go API 决定。
- [x] 同时适用 MVP 与 Multi-Tenant Gate；受控试点前必须完成其隔离、额度、备份恢复、轮换和运营控制。

### Gate evidence and required delivery artifacts

- **MVP Gate**: CPU 与 Ascend NPU 完整生命周期、批准 Profile、持久卷、Outbox、generation、
  非特权 Adapter、健康检查和运行时集成测试均为一期必交付。
- **Multi-Tenant Gate**: 双班级隔离与默认拒绝网络暴露、班级/用户配额、拒绝访问审计、备份恢复验证、
  生命周期指标与告警、租户授权契约测试、管理员访问/代操作策略以及凭证轮换流程必须在试点开放前完成。
- **硬件准入**: 以目标镜像、CANN、K3s 与 device-share 的实际发现/隔离结果验证 8T/20T；每节点 3 个
  NPU 工作区并发通过后，才冻结 Adapter 资源映射。任何失败只可形成可追踪拒绝或等待，不得猜测映射。
- **迁移**: 每个迁移记录锁与语句超时、事务模式、兼容窗口、预期时长、验证查询、恢复及演练；破坏性
  变更使用 expand-migrate-contract 和 roll-forward。
- **契约**: `contracts/phase1.openapi.yaml` 是一期控制面草案。身份、班级、RBAC、Profile、工作区、
  终端、培训期处置、任务、审计和健康端点发布前统一冻结。

## Project Structure

## DDD boundaries and integration rules

| Bounded context | Aggregate roots | Owns | Cross-context interaction |
|---|---|---|---|
| Identity | User | stable external-subject mapping and subject state | exposes stable User ID only |
| Authorization | Role, Permission, RoleBinding | action definitions and scoped grants | application authorization decision; never frontend-only |
| Class | Class, ClassMembership | membership, training period, Profile enablement and quotas | emits membership/quota policy changes by stable IDs |
| Workspace | Workspace, WorkspaceVolume, WorkspaceOperation | lifecycle, volume binding, generation and desired state | invokes runtime/storage ports; writes Outbox atomically |
| Task | LongRunningTask, TaskWorkspace, TaskGrant | isolated task resources and task-scope access | uses Workspace-style ports, never student Workspace ownership |
| Terminal | TerminalRecord | filtered teaching-process evidence and capture gaps | consumes authorized session/runtime evidence only |
| Audit | AuditRecord, OutboxEvent | durable security and business evidence | shared append-only evidence, not a generic domain dependency |

Each context owns its repository and transaction rules. Application services orchestrate across contexts using stable IDs,
read models or immutable events; they must not import another context's aggregate or adapter. `Workspace` and
`TaskWorkspace` use separate aggregates and volumes even when they share a runtime implementation.

### Documentation

```text
specs/001-cpu-workspace-mvp/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── frontend-prototype.md             # 契约冻结后按班级/NPU/任务范围更新
├── adrs/
│   ├── 0001-single-node-kubernetes-runtime.md
│   └── 0002-phase1-ascend-and-persistent-volume.md
├── contracts/
│   ├── phase1.openapi.yaml
│   └── frontend-ui.md                 # 响应式、组件和加载状态契约
└── tasks.md                          # 由 /speckit-tasks 生成
```

### Source Code (planned greenfield layout)

```text
cmd/{api,worker}/
internal/
├── identity/{domain,application,transport,adapter}/
├── authorization/{domain,application,transport,adapter}/
├── class/{domain,application,transport,adapter}/
├── workspace/{domain,application,transport,adapter/{postgres,k3s}}/
├── terminal/{domain,application,transport,adapter}/
├── task/{domain,application,transport,adapter}/
├── audit/{domain,application,adapter}/
└── platform/                         # composition, config, tracing, health only
migrations/
tests/{architecture,contract,integration,e2e}/
frontend/
├── app/                               # App Router 路由、layout、loading、error
├── components/{ui,layout,features,skeletons}/
├── lib/{bff,utils}/
└── tests/                             # 组件、集成和端到端证据
Makefile
```

**Structure Decision**: 采用 Go 模块化单体与独立 API/Worker 组合根。领域包不导入 HTTP、数据库、
K3s、Ascend 或存储 SDK；运行时和采集细节只在 Adapter 中。Next.js 仅作为 BFF/呈现层，不持有数据库
凭据、不执行权威授权，也不转发用户 ID/刷新令牌。

## Delivery Sequence

1. 建立 Go/Next.js、迁移、验证、追踪、健康、OIDC 测试身份与受控 K3s/存储/采集测试基线。
2. 实现 Identity、Class、可扩展 RBAC、班级/用户配额、拒绝审计和管理员代操作政策，先验证双班级隔离。
3. 实现 Workspace/Volume/Operation 聚合、CPU/NPU Profile、名称约束、幂等、Outbox 和 generation。
4. 实现 K3s CPU/Ascend Adapter、卷绑定、NPU 准入/编译队列与协调恢复；以 8T/20T 硬件验证冻结映射。
5. 冻结 OpenAPI 与前端 UI 契约；按 DDD read model 更新每页/每个弹窗的前端原型，先交付共享
   12 栏 shell、shadcn/ui 基础组件和 route/component Skeleton，再并行实现工作区门户与教师终端过程视图。
6. 实现训练期结束处置和独立 Task Workspace，随后完成备份恢复、凭证轮换、指标告警与试点验收。

## Validation Plan

实现后必须提供并在每次提交前运行的统一入口：

```text
make format-check
make lint
make test-unit
make test-integration
make test-contract
make test-e2e
make architecture-check
make verify
```

`make verify` 聚合适用检查。端到端验收至少覆盖：CPU 20 次创建、CPU/NPU 持久数据、NPU 每节点三并发、
双班级拒绝与不可枚举、WebIDE/SSH/VS Code Remote-SSH 入口、终端过滤/归档、培训期结束、任务工作区隔离、
重复/超时/中断协调、备份恢复和审计/指标/健康证据。

## Complexity Tracking

无宪法例外。Ascend device-share 的具体资源键和部署参数不是公开设计决策，必须经目标硬件兼容性验证后
封装于 Adapter；在此之前不能开始依赖该映射的实现任务。
