#import "../template/project-kit.typ": *

#show: project-document.with(
  title: "异构算力容器教学服务平台设计方案",
  subtitle: "需求、架构、基础设施与实施设计",
  doc-type: "SYSTEM DESIGN REPORT",
  version: "V1.0",
  date: "2026-07-21",
  organization: "项目组",
  owner: "冶秉礼",
  toc: true,
)

= 执行摘要

本项目拟建设一套面向高校教学和实验实训的 *异构算力容器服务平台*。平台以课程、班级和实验为业务主线，为学生提供可启动、暂停、恢复和重置的持久化工作区，并统一接入 Ascend 310B SBC、ARM、x86、CUDA 等不同计算设施。教师可发布实验镜像及 Demo、观察学生终端、查看实验进度、发起环境自检和实施教学辅助；学生可通过统一身份登录，在隔离环境中完成编译、算子开发、模型推理及服务部署。

平台在软件设计上采用 *领域驱动设计（DDD）战略建模 + 模块化单体控制面*，将教学、工作区、算力、实验执行、终端、镜像构建和制品存储划分为独立限界上下文。Kubernetes、Ascend Runtime、CUDA Device Plugin、对象存储及镜像仓库均通过防腐层接入，避免基础设施对象侵入核心领域模型。随着规模增长，Terminal Gateway、Cluster Agent 和 Build Worker 可独立扩容，核心限界上下文也可按边界平滑拆分为服务。

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 8pt,
  metric-card([首期建议周期], [24 周], detail: [从立项到 30 人课程试点]),
  metric-card([试点并发目标], [30 / 12], detail: [30 人在线、约 12 人并发 NPU]),
  metric-card([核心架构], [多集群], detail: [统一控制面 + 异构执行集群]),
)

#v(10pt)
#callout(
  [管理层建议],
  [首期不建设“大而全”的私有云，不将所有异构节点强行纳入单一集群。应先以 4-8 块 Ascend SBC 完成闭环验证，再扩充至 12-16 块开展 30 人课程试点。硬件采购必须以真实并发 NPU 时长、工作区容量和镜像增长数据为扩容依据。],
  tone: "teal",
)

== 项目关键决策

#table(
  columns: (31mm, 1fr, 1fr),
  table.header([*决策主题*], [*推荐方案*], [*管理理由*]),
  [系统边界], [统一教学控制面管理多个相对同质的执行集群。], [降低 ARM/x86、Ascend/CUDA 驱动及运行时耦合。],
  [软件架构], [DDD 模块化单体；Terminal、Agent、Builder 独立部署。], [兼顾早期交付效率和后期演进能力。],
  [算力占用], [开发工作区与临时 NPU 执行任务分离。], [避免学生编辑代码期间长期占用稀缺设备。],
  [存储], [镜像根文件系统只读，个人目录 PVC 持久化。], [环境可重建、数据可恢复、课程内容可控。],
  [构建安全], [Rootless BuildKit 独立构建池。], [禁止向学生暴露 Docker Socket 或宿主机高权限。],
  [终端审计], [xterm.js + Terminal Gateway；ttyd 仅用于原型。], [支持短期令牌、教师观察、控制权与录像审计。],
)

= 项目背景与立项目标

== 背景说明

教学任务需要同时覆盖普通 Linux 编程、ARM 边缘计算、Ascend 算子开发、PyTorch/torch-npu、CUDA 兼容验证以及学生自定义服务部署。传统做法通常依赖教师手工分配设备、重复创建账户、维护共享环境，并通过聊天或现场巡查判断学生进度，存在以下问题：

- 不同架构、驱动和框架版本缺乏统一抽象，实验环境容易漂移。
- 学生工作数据随容器或设备重装丢失，环境恢复成本高。
- 教师难以批量下发 Demo、检查环境和掌握班级进度。
- 终端共享和远程协助缺乏身份校验、授权和审计。
- 镜像构建、漏洞扫描及发布过程缺乏统一治理。
- 对外 API、服务暴露和端口管理容易绕过平台安全边界。

== 项目愿景

构建一个“*课程即组织、实验即模板、工作区即服务、算力即能力*”的教学基础设施，使教师能够用统一的课程模型组织异构算力实验，使学生能够随时获得可恢复、可审计、可复现的实验环境。

== 业务目标

#table(
  columns: (19mm, 1fr, 1fr, 35mm),
  table.header([*编号*], [*目标*], [*衡量方式*], [*首期目标值*]),
  [G-01], [课程环境标准化], [同一实验模板启动后的环境自检通过率], [≥ 95%],
  [G-02], [降低教学准备成本], [教师创建班级到发布可用实验的操作时间], [≤ 30 分钟],
  [G-03], [提高环境恢复效率], [学生从异常状态恢复到可用环境的时间], [≤ 5 分钟],
  [G-04], [提升教学可视化], [教师可查看的关键实验步骤覆盖率], [≥ 90%],
  [G-05], [保障多租户隔离], [越权访问、跨班级数据泄露事件], [0 起],
  [G-06], [形成扩展能力], [新增一种计算设施适配所需核心域改动], [原则上为 0],
)

== 技术目标

- 建立可演进的 DDD 领域模型和稳定的上下文边界。
- 抽象 ComputeProfile、ComputePool、ResourceLease 等统一算力概念。
- 支持 ARM64、x86_64、Ascend、CUDA 和 CPU-only 计算配置。
- 支持容器工作区生命周期、PVC 持久化、备份和恢复。
- 支持 OIDC 单点登录、课程角色授权及账户身份绑定。
- 支持 Web Terminal、教师只读观察、协助与操作审计。
- 支持镜像构建、扫描、自检、发布和兼容矩阵管理。
- 支持学生服务部署及范围受控的 HTTP/API 暴露。

= 项目范围

== 范围内

#table(
  columns: (33mm, 1fr),
  table.header([*工作包*], [*主要内容*]),
  [教学管理], [课程、班级、成员、教师/助教/学生角色、实验模板、实验版本与发布。],
  [工作区管理], [创建、启动、停止、重建、重置、恢复、配额、空闲回收和状态展示。],
  [异构算力], [多集群注册、能力发现、资源匹配、租约、节点健康及 Ascend 自检。],
  [Web 终端], [短期会话令牌、终端连接、教师观察、协助、控制权和录像索引。],
  [存储与制品], [个人 PVC、课程只读内容、数据集、Demo、提交物、对象存储和检查点。],
  [镜像管理], [基础镜像、课程镜像、Dockerfile 构建、扫描、自检、审批和 Harbor 发布。],
  [服务部署], [学生镜像部署、受控端口、私有/课程可见范围、Ingress/API Gateway 接入。],
  [平台治理], [统一认证、RBAC、审计、可观测、配额、备份、告警和运维手册。],
)

== 范围外

首期明确不包含：

- 通用公有云计费、复杂账单和商业支付系统。
- 超大规模分布式训练调度和跨地域容灾。
- 完整替代 GitHub/GitLab 的源代码托管平台。
- 为内核模块、宿主机驱动或高权限实验提供普通共享容器。
- 对任意 Dockerfile 的无条件联网构建和任意特权运行。
- 一期即建设完整 Ceph、Service Mesh 或十余个微服务。

== 假设与约束

- 首期服务对象为约 30 名学生，峰值同时在线约 20-30 人。
- Ascend 设备按保守模型视为稀缺独占资源，vNPU 能力需单独验证后启用。
- SBC 主要作为执行节点，不承担生产数据库、镜像仓库和控制平面职责。
- 控制面及存储优先部署在稳定 x86 服务器和集中存储设备上。
- 教学管理和资源调度规则仍可能变化，故首期以模块化单体降低变更成本。

= 利益相关方与项目治理

== 利益相关方

#table(
  columns: (31mm, 35mm, 1fr, 1fr),
  table.header([*角色*], [*关注重点*], [*主要责任*], [*参与方式*]),
  [项目发起人], [教学效果、预算、交付], [批准范围、预算和重大变更], [里程碑评审],
  [课程教师], [易用性、进度、实验复现], [定义实验、验收教学流程], [双周评审、试点],
  [学生代表], [性能、稳定性、操作体验], [参与用户测试和反馈], [原型评审、UAT],
  [项目经理], [范围、进度、风险、质量], [计划、协调、报告和变更控制], [全程],
  [架构负责人], [边界、可靠性、安全], [架构决策和技术评审], [全程],
  [研发团队], [可维护性、交付效率], [设计、开发、测试和文档], [迭代交付],
  [平台运维], [可部署、可监控、可恢复], [环境、监控、备份和故障处置], [设计至运营],
  [安全负责人], [身份、隔离、审计], [威胁建模和安全验收], [关键评审],
)

== 治理机制

- *周例会*：进度、阻塞、风险、下周计划，控制在 45 分钟内。
- *双周迭代评审*：演示可运行增量，教师和学生代表参与。
- *架构决策记录（ADR）*：所有影响边界、数据、安全和基础设施的关键决策需归档。
- *阶段门评审*：需求基线、架构基线、MVP、试点上线和项目验收。
- *变更控制*：影响时间超过 5 个工作日、预算超过基线 10% 或改变核心范围的请求需提交变更委员会。

== 项目组织建议

#table(
  columns: (35mm, 25mm, 1fr),
  table.header([*岗位*], [*建议投入*], [*职责*]),
  [项目经理/产品负责人], [1 人], [范围、需求优先级、进度、风险和跨角色协调。],
  [技术/领域架构师], [1 人], [DDD 建模、架构边界、接口、安全和技术决策。],
  [后端工程师], [2 人], [控制面、领域模块、API、工作流和数据层。],
  [前端工程师], [1-2 人], [课程门户、工作区、终端和教师看板。],
  [平台/SRE 工程师], [2 人], [Kubernetes、Cluster Agent、存储、CI/CD、监控。],
  [测试工程师], [1 人], [自动化、兼容、性能、安全和验收测试。],
  [Ascend/硬件专家], [0.5-1 人], [驱动、CANN、设备插件、自检和镜像兼容。],
  [安全顾问], [按需], [威胁建模、渗透和安全基线评审。],
)

= 需求设计

== 用户角色与权限边界

#table(
  columns: (31mm, 1fr, 1fr),
  table.header([*角色*], [*允许操作*], [*禁止/受限操作*]),
  [平台管理员], [管理集群、计算配置、镜像策略、全局审计和平台配置。], [不得绕过审计直接修改学生数据。],
  [课程负责人], [创建课程、配置配额、添加教师和批准课程镜像。], [不能操作其他课程资源。],
  [教师], [发布实验、查看进度、观察终端、重置课程工作区。], [默认不能读取学生私人目录内容。],
  [助教], [查看状态、协助排错、批改和有限重置。], [权限不得超过课程负责人。],
  [学生], [使用本人或本组工作区、提交作业、部署受控服务。], [不得访问 K8s API、宿主机、其他租户或任意端口。],
  [服务账户], [在授权 Scope 内调用 API。], [不允许交互式登录，令牌必须可撤销。],
)

== 核心功能需求

#table(
  columns: (19mm, 17mm, 1fr, 42mm),
  table.header([*编号*], [*优先级*], [*需求说明*], [*验收摘要*]),
  [FR-01], [#priority-badge("P0")], [支持 OIDC 登录、课程临时身份和经过验证的账户绑定。], [身份合并后课程、工作区和提交物保持归属。],
  [FR-02], [#priority-badge("P0")], [支持课程、班级、Enrollment 和角色授权。], [跨课程资源访问被拒绝并记录审计。],
  [FR-03], [#priority-badge("P0")], [支持基于 LabRelease 创建学生工作区。], [30 人批量创建成功率 ≥ 95%。],
  [FR-04], [#priority-badge("P0")], [支持工作区启动、停止、重建、重置和恢复。], [停止后释放计算资源，PVC 保留。],
  [FR-05], [#priority-badge("P0")], [支持 ComputeProfile 与异构资源匹配。], [CPU、ARM、Ascend 三类配置可成功调度。],
  [FR-06], [#priority-badge("P0")], [支持 Ascend 节点、镜像及实验三级自检。], [故障节点被自动阻止调度。],
  [FR-07], [#priority-badge("P0")], [提供 Web 终端和短期会话令牌。], [会话不能通过静态 URL 重放。],
  [FR-08], [#priority-badge("P1")], [教师可只读观察、协助或接管终端。], [进入和控制权变化均产生可查询审计。],
  [FR-09], [#priority-badge("P1")], [支持课程 Demo 只读挂载和初始化复制。], [学生可恢复原始 Demo。],
  [FR-10], [#priority-badge("P1")], [支持 Dockerfile/仓库构建和镜像发布。], [构建、扫描、自检通过后方可用于课程。],
  [FR-11], [#priority-badge("P1")], [支持实验事件与进度看板。], [教师可查看环境、编译、测试、提交等步骤。],
  [FR-12], [#priority-badge("P2")], [支持学生服务部署和受控 API 暴露。], [默认仅本人或课程可见，公网需审批。],
)

== 非功能需求

#table(
  columns: (25mm, 1fr, 40mm),
  table.header([*类别*], [*要求*], [*首期指标*]),
  [可用性], [课程时段核心控制面应保持可用；单一 SBC 故障不影响其他工作区。], [月度可用性目标 99.5%],
  [性能], [门户常用查询、工作区操作和终端连接具备可接受响应。], [P95 API < 1 s；终端首连 < 5 s],
  [扩展性], [控制面与执行集群解耦；Terminal、Agent、Worker 可独立扩容。], [支持至少 3 类集群和 100 个工作区对象],
  [安全性], [默认拒绝网络策略、最小权限、非特权容器、令牌短期化。], [高危越权漏洞为 0],
  [可恢复性], [数据库、对象存储和课程配置具备备份；工作区支持恢复。], [RPO ≤ 24 h；RTO ≤ 4 h],
  [可维护性], [领域边界清晰，核心域不依赖 Kubernetes/厂商对象。], [模块依赖检查通过],
  [可观测性], [日志、指标、审计和关联 ID 可追踪完整请求链路。], [P0/P1 操作审计覆盖率 100%],
  [兼容性], [镜像明确声明架构、运行时、加速器和框架兼容信息。], [不兼容镜像禁止调度],
)

= DDD 领域设计

== 设计原则

#callout(
  [核心原则：DDD 不等于微服务],
  [首期采用 DDD 战略设计建立业务边界，以模块化单体承载主要控制面。限界上下文首先是模型、事务和团队协作边界，而不是必须独立部署的服务。只有在负载、发布节奏、安全边界或组织边界明确分离时，才拆分为独立服务。],
  tone: "blue",
)

DDD 落地遵循以下约束：

- 核心领域不直接引用 Kubernetes Pod、PVC、Node、CUDA Resource 或 Ascend 设备路径。
- 跨上下文通过应用服务接口、稳定标识和领域事件交互，不共享 ORM Entity。
- 强一致业务规则封装在聚合内，长流程由 Process Manager/Saga 协调。
- 数据库事务与领域事件使用 Transactional Outbox 保证可靠性。
- 供应商和基础设施 SDK 通过 Anti-Corruption Layer 转换为领域模型。

== 领域分类

#table(
  columns: (28mm, 37mm, 1fr),
  table.header([*领域类型*], [*限界上下文*], [*职责*]),
  [核心域], [Teaching], [课程、班级、Enrollment、实验定义、实验发布和教学策略。],
  [核心域], [Workspace], [学生工作区生命周期、代次、状态、存储绑定和恢复规则。],
  [核心域], [Compute], [ComputeProfile、能力、资源池、资源租约和异构分配策略。],
  [核心域], [LabExecution], [实验运行、环境检查、步骤、测试结果、进度和提交。],
  [支撑域], [Terminal], [会话、参与者、观察/协助/接管、控制权和录像索引。],
  [支撑域], [ImageBuild], [构建来源、架构、扫描、自检、审批和发布镜像。],
  [支撑域], [Artifact], [Demo、数据集、提交物、制品版本和访问策略。],
  [支撑域], [Checkpoint], [备份、快照、恢复点和保留策略。],
  [支撑域], [Deployment], [镜像服务化、端口、可见范围、域名和生命周期。],
  [通用域], [Identity/Auth/Audit], [OIDC、RBAC、令牌、审计、通知和可观测。],
)

== 上下文地图

#block(fill: colors.panel, stroke: 0.5pt + colors.border, radius: 5pt, inset: 10pt)[
  #grid(
    columns: (1fr, 10mm, 1fr, 10mm, 1fr),
    row-gutter: 9pt,
    align: center + horizon,
    architecture-node([Identity], [OIDC、身份绑定、统一用户标识], tone: "teal"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([Teaching], [课程、班级、实验发布、Enrollment], tone: "blue"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([LabExecution], [步骤、检查、结果、进度、提交], tone: "green"),

    architecture-node([Authorization], [课程范围 RBAC、资源授权], tone: "amber"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([Workspace], [生命周期、状态机、PVC、代次], tone: "blue"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([Terminal Checkpoint], [终端会话、观察、录像、恢复], tone: "teal"),

    architecture-node([ImageBuild], [构建、扫描、自检、发布], tone: "amber"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([Compute], [Profile、Pool、Lease、调度策略], tone: "red"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([Cluster ACL], [Kubernetes、Ascend、CUDA 适配器], tone: "blue"),
  )
]

== 核心聚合

=== Teaching Context

主要聚合及实体：

- `Course`：课程基本信息、所有者、状态和课程级策略。
- `ClassGroup`：教学班或实验小组。
- `Enrollment`：用户在课程中的角色和有效期。
- `LabDefinition`：实验的逻辑定义。
- `LabRelease`：不可变的实验发布版本，引用镜像、Demo、ComputeProfile 和检查规则。

关键不变量：同一用户在同一课程只能有一个有效 Enrollment；已发布实验不可原地修改；助教权限不得超过课程负责人；课程关闭前必须处理运行中的工作区。

=== Workspace Context

`Workspace` 聚合建议字段：

```yaml
workspace_id: ws-...
owner_id: user-...
course_id: course-...
lab_release_id: labrel-...
compute_profile_id: cp-...
storage_binding: pvc-...
status: running
generation: 5
current_instance_id: instance-...
```

状态机：

```text
Pending -> Provisioning -> Running -> Stopping -> Stopped
                         \-> Failed
Stopped -> Starting | Resetting | Restoring | Deleting
```

`generation` 用于抵御异步任务乱序：旧代次任务完成后不得覆盖新代次状态。停止工作区仅删除运行实例并释放计算租约，默认保留个人存储。

=== Compute Context

核心模型：

- `ComputeProfile`：业务可理解的算力需求模板。
- `ComputePool`：某执行集群中具有相同能力和策略的一组资源。
- `Capability`：架构、加速器、运行时、框架和特性描述。
- `ResourceRequest`：工作区或任务发起的资源需求。
- `ResourceLease`：具有状态、过期时间和幂等键的资源占用凭证。

```yaml
compute_profile:
  architecture: arm64
  accelerator:
    vendor: huawei
    family: ascend
    model: 310b
    count: 1
  runtime:
    type: cann
    version_range: "8.x"
  features:
    - ascend-c
    - torch-npu
    - profiling
  resources:
    cpu: "4"
    memory: 8Gi
```

关键不变量：资源池必须满足全部强约束；独占设备同一时刻只能存在一个有效 Lease；不健康资源不得分配；Lease 释放操作必须幂等。

=== Terminal Context

`TerminalSession` 聚合包含 SessionId、WorkspaceId、Owner、Participants、Mode、ControlOwner、StartedAt、EndedAt 和 RecordingReference。

模式分为：

- `Private`：仅学生本人。
- `Observe`：教师只读观看。
- `Assist`：按策略允许协同输入。
- `Takeover`：教师临时取得控制权，学生界面必须明确提示。

=== ImageBuild Context

状态机：

```text
Submitted -> Validating -> Queued -> Building
          -> Scanning -> SelfTesting -> Published
```

发布条件为：构建成功、安全策略通过、架构元数据完整、兼容信息完整、目标硬件自检成功。

== 跨域流程与领域事件

=== 工作区开通过程

```text
WorkspaceRequested
  -> 验证课程成员与实验权限
  -> 申请 ResourceLease
  -> 准备 PVC / LabPackage
  -> Cluster Agent 创建工作负载
  -> 节点/镜像/实验自检
  -> WorkspaceProvisioned / WorkspaceProvisionFailed
```

失败补偿必须释放租约、清理未完成工作负载，并依据失败阶段决定保留或回收 PVC。

=== 主要领域事件

`StudentEnrolled`、`LabPublished`、`WorkspaceRequested`、`ResourceLeaseGranted`、`WorkspaceProvisioned`、`WorkspaceStopped`、`HardwareCheckFailed`、`TerminalSessionStarted`、`TeacherJoinedTerminal`、`TerminalControlTransferred`、`CheckpointRestored`、`ImagePublished`、`ServiceDeployed`。

== 代码组织建议

```text
cmd/
  platform-api/
  platform-worker/
  cluster-agent/
  terminal-gateway/
  build-worker/

internal/
  teaching/{domain,application,infrastructure,interfaces}
  workspace/{domain,application,infrastructure,interfaces}
  compute/{domain,application,infrastructure,interfaces}
  labexecution/
  terminal/
  imagebuild/
  artifact/
  checkpoint/
  deployment/
  identity/
  authorization/
  audit/

adapters/
  kubernetes/
  ascend/
  cuda/
  keycloak/
  harbor/
  minio/
```

= 总体技术架构

== 逻辑架构

#block(fill: colors.panel, stroke: 0.5pt + colors.border, radius: 5pt, inset: 10pt)[
  #grid(
    columns: (1fr, 8mm, 1fr),
    row-gutter: 8pt,
    align: center + horizon,
    architecture-node([Web 教学门户], [课程、实验、工作区、终端、文件、教师看板], tone: "blue"),
    text(size: 18pt, fill: colors.muted)[→],
    architecture-node([API Gateway / OIDC], [统一入口、限流、令牌、Scope 与审计], tone: "teal"),

    architecture-node([平台控制面], [DDD 模块化单体：Teaching、Workspace、Compute、LabExecution 等], tone: "blue"),
    text(size: 18pt, fill: colors.muted)[↔],
    architecture-node([平台数据服务], [PostgreSQL、Outbox、Redis（可选）、Keycloak], tone: "green"),

    architecture-node([独立网关与 Worker], [Terminal Gateway、Build Worker、Background Worker], tone: "amber"),
    text(size: 18pt, fill: colors.muted)[↔],
    architecture-node([制品与可观测], [Harbor、MinIO、Prometheus、Loki、Grafana], tone: "teal"),

    architecture-node([Resource Broker], [选择 Cluster/Pool，签发 Lease，维护幂等和补偿], tone: "red"),
    text(size: 18pt, fill: colors.muted)[↔],
    architecture-node([Cluster Agent], [每个执行集群部署，主动连接控制面并操作本地 K8s], tone: "blue"),

    architecture-node([Ascend ARM 集群], [Orange Pi / 310B、CANN、torch-npu、Ascend C], tone: "red"),
    text(size: 18pt, fill: colors.muted)[＋],
    architecture-node([x86 / CUDA / CPU 集群], [普通教学、构建、CUDA 验证和服务部署], tone: "blue"),
  )
]

== 物理部署原则

- 控制面、数据库、镜像仓库和集中存储运行在稳定 x86 服务器。
- SBC 作为纯执行节点，不承载生产 etcd、主数据库和镜像仓库。
- 各执行集群部署 Cluster Agent，通过 mTLS 主动连接控制面。
- 集群管理员凭据不直接存放在平台业务数据库或前端。
- Terminal Gateway 和 Build Worker 与 API 进程隔离并可独立扩容。

== Cluster Agent

每个执行集群部署一个 Agent，职责包括：

- 向控制面上报集群、节点、设备和运行时能力。
- 将领域层的 WorkspaceSpec、ComputeProfile 转换为本地 Kubernetes 对象。
- 创建/删除工作负载、PVC、Service、NetworkPolicy 和 ResourceQuota。
- 执行幂等命令并按 generation 拒绝过期操作。
- 聚合 Ascend/CUDA 设备健康和节点自检结果。
- 在控制面网络不可达时维持已有工作负载，不接受未授权新任务。

== Web Terminal

首期可用 ttyd 验证交互，但正式方案采用：

```text
Browser xterm.js
  -> Terminal Gateway (OIDC、短期 Session Token、审计)
  -> Cluster Agent / Kubernetes exec & attach
  -> Workspace Container
```

Terminal Gateway 记录 connect、disconnect、stdin、stdout、resize 和 control-owner 事件。录像存入对象存储，数据库仅保存索引、权限和保留期。终端页面应采用独立域名、严格 CSP，禁止第三方统计脚本读取输入。

= 异构算力与硬件自检

== 三层抽象

#table(
  columns: (28mm, 1fr, 1fr),
  table.header([*层次*], [*平台模型*], [*基础设施实现*]),
  [业务层], [教师选择“Ascend 310B 算子开发”“CUDA 推理”等 ComputeProfile。], [不暴露 nodeSelector、扩展资源名和 RuntimeClass。],
  [资源层], [Resource Broker 匹配 Capability、Pool、配额和策略。], [节点标签、亲和性、设备插件、DRA/扩展资源。],
  [适配层], [Cluster ACL 将统一模型翻译为厂商配置。], [Ascend Runtime/Device Plugin、NVIDIA Runtime/Device Plugin。],
)

== Ascend 自检设计

=== 节点级自检

DaemonSet/Agent 周期检查：设备节点、驱动、固件、`npu-smi`、CANN Runtime、容器运行时、Device Plugin 注册、温度、磁盘、网络、时间同步和最小算子。异常节点被标记为不可调度，并产生 `HardwareCheckFailed` 事件。

=== 镜像级自检

镜像必须声明离线可执行的 `selfcheck`：框架 import、设备枚举、最小 Tensor 运算、编译器和运行时版本兼容。自检结果与镜像 digest 绑定，镜像变化后必须重新执行。

=== 实验级自检

教师通过 LabRelease 定义环境、编译、正确性和性能检查。建议统一提供：

```bash
labctl status
labctl check environment
labctl check build
labctl check correctness
labctl benchmark
labctl submit
```

这些命令应产生结构化 LabEvent，教师看板不依赖分析 Shell 历史来猜测学生进度。

== 资源使用模式

优先采用“*开发工作区 + 按需执行任务*”模式：

#table(
  columns: (38mm, 1fr, 1fr),
  table.header([*模式*], [*说明*], [*适用场景*]),
  [交互式设备工作区], [进入工作区即占用 NPU，停止后释放。], [Profiling、硬件调试、需要持续设备上下文。],
  [按需 NPU Job], [工作区常驻 CPU/ARM 环境，运行测试时临时申请 NPU。], [算子编译、正确性测试、推理和 Benchmark。],
)

首期默认按需模式，以提高 NPU 利用率；交互式设备模式由教师配置配额和最长占用时间。

= 数据、存储与环境恢复

== 存储布局

```text
/                 镜像根文件系统，默认只读
/workspace        学生个人可写 PVC
/course           课程 Demo，只读挂载
/datasets         共享数据集，按课程授权只读
/tmp              临时目录，不保证持久化
```

== 数据分类

#table(
  columns: (32mm, 1fr, 1fr, 30mm),
  table.header([*数据*], [*存储*], [*保护策略*], [*建议保留*]),
  [课程、权限和状态], [PostgreSQL], [每日备份、事务一致性、审计], [长期],
  [学生工作区], [PVC/NFS/CSI], [配额、快照或压缩备份], [课程期 + 30 天],
  [镜像], [Harbor], [不可变标签、扫描、垃圾回收], [按版本策略],
  [Demo/数据集/提交物], [MinIO], [版本、Digest、签名 URL、生命周期], [课程策略],
  [终端录像], [MinIO], [加密、最小访问、自动到期], [30-90 天],
  [监控日志], [Prometheus/Loki], [分级保留、容量告警], [15-90 天],
)

== 重置与恢复

- *软重置*：删除并重建 Pod，保留 PVC。
- *文件重置*：清理指定工作区目录，从 LabPackage 重新初始化。
- *检查点恢复*：从 CSI Snapshot 或对象存储备份恢复 PVC。
- *完整重建*：依据不可变 LabRelease、Image digest 和 Demo digest 重建环境。

任何恢复操作必须记录发起人、原因、恢复点、目标代次和结果。

= 镜像构建与发布治理

== 镜像分层

```text
OS Base
  -> Accelerator Runtime（CANN / CUDA / CPU-only）
  -> Framework（torch-npu / PyTorch / TensorFlow / Ascend C）
  -> Course Image（具体课程与实验工具）
```

每个 ImageProfile 必须记录：架构、OS、加速器、运行时、框架版本、驱动约束、入口、健康检查、SBOM/扫描结果和发布审批。

== 构建流程

```text
Dockerfile / Git Source
  -> 静态策略检查
  -> Rootless BuildKit（隔离构建池）
  -> 镜像扫描与 SBOM
  -> 目标架构/硬件自检
  -> 审批
  -> Harbor 发布
  -> ImageProfile 生效
```

禁止向学生工作区挂载 Docker Socket。构建任务默认无特权、无宿主机目录，并限制 CPU、内存、磁盘、时间和网络访问。

== CI/CD 策略

- 平台官方基础镜像使用 GitHub Actions/GitLab CI 触发内部 Builder。
- 教师和学生上传 Dockerfile 由平台 Build Service 统一排队和审计。
- ARM 原生构建优先使用 ARM Builder；可接受的镜像可采用多架构交叉构建，但必须在目标硬件自检。
- 镜像标签仅用于友好引用，部署记录必须固定 digest。

= API 与服务部署

== API 分层

- 外部公开：课程、工作区、构建、部署、镜像和计算配置 API。
- 内部应用：限界上下文之间的应用接口。
- Agent 协议：控制面与执行集群的命令、状态和事件协议。
- 基础设施接口：Kubernetes、Harbor、MinIO、Keycloak 等适配器。

== 鉴权

用户调用使用 OIDC Access Token；自动化调用使用 OAuth2 Client Credentials 或可撤销的 Scoped Token。Token 至少包含 subject、scope、course/resource scope、expiry 和 token id。高风险操作要求短时令牌和二次授权。

== 服务部署范围

#table(
  columns: (27mm, 1fr, 1fr),
  table.header([*范围*], [*访问者*], [*审批与限制*]),
  [private], [仅部署者本人], [默认选项，受 OIDC 保护。],
  [course], [课程成员], [教师可管理，禁止跨课程访问。],
  [campus], [校内网络或统一身份用户], [需教师审批和配额。],
  [public], [公网], [需管理员审批、域名、限流和安全扫描。],
)

学生不得直接创建 HostPort、NodePort、hostNetwork 或任意 Ingress。平台将受控 DeploymentSpec 转换为 Deployment、Service 和 HTTPRoute/Ingress。

= 安全设计

== 安全边界

#table(
  columns: (34mm, 1fr, 1fr),
  table.header([*环境类别*], [*安全基线*], [*适用范围*]),
  [普通教学容器], [非 root、禁止提权、默认 seccomp、drop capabilities、只读根文件系统、默认拒绝网络。], [Python、C/C++、Java、普通应用。],
  [硬件加速容器], [仅通过 RuntimeClass、Device Plugin/CDI/DRA 暴露设备，不因设备访问启用 privileged。], [CANN、CUDA、torch-npu。],
  [系统级实验], [独立 VM/KubeVirt/Kata/专用节点或隔离集群。], [内核模块、驱动、Docker daemon、宿主网络。],
)

== 威胁与控制

#table(
  columns: (1fr, 1fr, 1fr),
  table.header([*主要威胁*], [*控制措施*], [*验证方式*]),
  [跨租户文件或网络访问], [Namespace/租户边界、NetworkPolicy、对象级授权、不可猜测 ID。], [越权自动化测试和渗透测试。],
  [恶意镜像/构建脚本], [Rootless Builder、资源限制、网络策略、扫描、审批。], [构建逃逸和策略绕过测试。],
  [终端会话劫持], [短期一次性 Token、Origin/CSP、mTLS、会话绑定。], [重放、跨站和过期令牌测试。],
  [教师权限滥用], [显式观察提示、最小权限、审计和保留策略。], [审计抽查和权限矩阵测试。],
  [设备/驱动故障], [三级自检、节点隔离、备用节点、版本矩阵。], [故障注入和恢复演练。],
  [凭据泄露], [Secret Manager/K8s Secret、短期凭据、轮换和日志脱敏。], [密钥扫描和应急演练。],
)

= 硬件基础设施评估

== 容量估算基线

首期试点按以下口径规划：注册学生 30 人；同时在线 20-30 人；并发 NPU 10-15 人；每人工作区 20-30 GB；每人保留 1-2 个检查点；课程镜像 10-20 个；日志及录像保留 30-90 天。

容量计算建议：

```text
工作区容量 = 学生数 × 单人配额 ×（1 + 检查点系数）
总可用容量 = 工作区 + 镜像 + 构建缓存 + 数据集 + 日志录像 + 备份预留
目标磁盘使用率应长期低于 70%-75%
```

以 30 人、25 GB/人、2 个等效检查点计算，工作区及检查点约需 2.25 TB；叠加镜像、缓存、数据集、日志和增长空间后，试点建议 12-20 TB 可用容量。

== A 档：开发验证环境

#table(
  columns: (35mm, 1fr, 21mm, 1fr),
  table.header([*设备*], [*建议配置*], [*数量*], [*用途*]),
  [x86 开发服务器], [12-16 核、64 GB、2 TB NVMe、双网口], [1], [控制面、数据库、Harbor、MinIO、构建和监控（非 HA）。],
  [Ascend SBC], [Orange Pi AiPro 20T，主动散热，优先 NVMe/eMMC], [4-8], [设备调度、自检、课程闭环和并发验证。],
  [备份/NAS], [8-12 TB 原始容量或现有 NAS], [1], [数据库、配置和对象备份。],
  [交换机], [16/24 口可管理千兆，支持 VLAN], [1], [管理与计算网络。],
  [UPS/PDU], [1-1.5 kVA，具备断电保护], [1 套], [控制面和存储安全关机。],
)

适用规模：研发团队和 5 人以内演示。该档不具备生产高可用，仅用于验证业务闭环和硬件兼容。

== B 档：30 人课程试点

#table(
  columns: (34mm, 1fr, 20mm, 1fr),
  table.header([*设备角色*], [*建议配置*], [*数量*], [*说明*]),
  [K3s/K8s 控制节点], [6-8 核、16-32 GB、512 GB 企业级 NVMe], [3], [仅运行控制面、etcd 和基础集群组件。],
  [平台应用节点], [12-16 核、64 GB、1 TB NVMe、10 GbE], [2], [API、Worker、Terminal、Keycloak、监控等。],
  [存储服务器], [8-16 核、64-128 GB ECC、12-20 TB 可用、双 NVMe、10 GbE], [1], [NFS/CSI、MinIO、Harbor 数据及备份。],
  [x86 构建节点], [16 核、64 GB、2 TB NVMe、10 GbE], [1], [BuildKit、扫描、多架构缓存。],
  [ARM 构建/验证节点], [ARM64、16-32 GB、NVMe], [1], [ARM 原生构建和无 NPU 兼容验证。],
  [Ascend SBC], [统一板型、主动散热、稳定供电、资产编号], [12-16], [约 10-12 个稳定并发 NPU，含备用和发布验证。],
  [CUDA 验证节点], [现有或租用单 GPU x86 节点], [0-1], [验证 CUDA ComputeProfile，不作为一期主采购。],
  [核心交换机], [24/48 口管理交换，2-4 个 10 GbE SFP+], [1], [SBC 千兆接入；存储、Builder 和应用 10 GbE。],
  [UPS/PDU/机架], [1.5-3 kVA，远程 PDU 优先], [1 套], [供电、散热和批量管理。],
)

== C 档：正式教学平台

正式教学阶段建议：3 个 16 核/32-64 GB 控制节点；3 个以上 16-32 核/64-128 GB 应用节点；高可用 PostgreSQL；双机 NAS 或 3 节点存储集群；30-60 TB 可用容量；32-48 块 Ascend SBC；x86 和 ARM Builder 各 2 台；冗余核心交换与双 10/25 GbE；分路 UPS。适用约 60-100 人注册、30-40 人并发 NPU，最终数量需由试点数据校准。

== 网络与机房要求

建议至少划分 Management、Storage、Compute、Ingress/Public 四个 VLAN。学生工作负载不得访问管理网络。SBC 使用千兆接入即可，但存储服务器、镜像仓库、构建节点和应用节点建议采用 10 GbE。所有设备应采用统一编号、稳定电源、主动散热和可替换存储介质。

== 采购策略

#callout(
  [建议分批采购],
  [第一批采购 4-8 块 Ascend SBC 和一套稳定 x86/存储基础设施，验证真实利用率、故障率、镜像尺寸和存储增长；达到阶段门后再采购至 12-16 块。避免在调度模型、vNPU 隔离和课程工作流尚未验证前一次性购置完整课堂规模。],
  tone: "amber",
)

= 项目实施计划

== 阶段与里程碑

#table(
  columns: (18mm, 31mm, 24mm, 1fr, 42mm),
  table.header([*阶段*], [*周期*], [*里程碑*], [*主要交付*], [*退出条件*]),
  [P0], [第 1-2 周], [M0 立项基线], [章程、需求清单、架构原则、设备盘点、风险基线。], [范围和关键决策获批。],
  [P1], [第 3-6 周], [M1 平台底座], [OIDC、课程/RBAC、K8s 环境、CI、PostgreSQL、基本门户。], [用户可登录并创建课程。],
  [P2], [第 7-12 周], [M2 工作区闭环], [Workspace、PVC、ComputeProfile、Cluster Agent、Ascend 自检。], [可创建并恢复 CPU/ARM/Ascend 工作区。],
  [P3], [第 13-18 周], [M3 教学闭环], [Web Terminal、教师观察、LabRelease、Demo、labctl、进度看板。], [完成端到端课堂演练。],
  [P4], [第 19-22 周], [M4 平台增强], [镜像构建、扫描、检查点、服务部署、API 和配额。], [安全和性能测试通过。],
  [P5], [第 23-24 周], [M5 试点验收], [试点运行、培训、文档、演练、问题闭环和验收报告。], [30 人试点通过验收标准。],
)

== 工作分解结构（WBS）

#table(
  columns: (18mm, 1fr, 28mm, 25mm),
  table.header([*WBS*], [*工作包*], [*责任角色*], [*完成阶段*]),
  [1.0], [项目管理、需求、范围、风险、采购与沟通], [项目经理], [全程],
  [2.0], [DDD 建模、ADR、接口和数据设计], [架构负责人], [P1-P2],
  [3.0], [身份、课程、班级、Enrollment、RBAC], [后端/前端], [P1],
  [4.0], [Workspace 状态机、存储、配额、恢复], [后端/SRE], [P2],
  [5.0], [ComputeProfile、ResourceLease、Cluster Agent], [后端/SRE], [P2],
  [6.0], [Ascend Runtime、设备插件、三级自检], [硬件专家/SRE], [P2],
  [7.0], [Terminal Gateway、xterm.js、观察和审计], [前端/后端], [P3],
  [8.0], [LabRelease、Demo、labctl、进度分析], [后端/教师代表], [P3],
  [9.0], [BuildKit、Harbor、扫描、自检和镜像治理], [SRE/后端], [P4],
  [10.0], [API Gateway、服务部署、外部 API], [后端/SRE], [P4],
  [11.0], [安全、性能、故障恢复和兼容测试], [测试/安全/SRE], [P4-P5],
  [12.0], [培训、运行手册、试点支持和验收], [全体], [P5],
)

== RACI

#table(
  columns: (1fr, 16mm, 16mm, 16mm, 16mm, 16mm, 16mm),
  table.header([*活动*], [*发起人*], [*PM*], [*教师*], [*架构*], [*研发*], [*运维*]),
  [范围与预算批准], [A], [R], [C], [C], [I], [C],
  [需求与验收标准], [I], [A/R], [R], [C], [C], [C],
  [DDD/总体架构], [I], [C], [C], [A/R], [R], [C],
  [基础设施采购], [A], [R], [C], [C], [I], [R],
  [功能开发], [I], [A], [C], [C], [R], [C],
  [安全与上线评审], [I], [A], [C], [R], [C], [R],
  [试点验收], [A], [R], [R], [C], [C], [R],
)

注：R = Responsible，A = Accountable，C = Consulted，I = Informed。

== 迭代管理

采用 2 周迭代。每个迭代必须交付可运行增量、自动化测试、变更日志和演示。需求按 P0/P1/P2 管理，P0 未完成前原则上不启动同域 P2 功能。每次发布必须具备回滚方案，数据库变更采用向前/向后兼容迁移。

= 质量保证与验收

== 测试策略

#table(
  columns: (28mm, 1fr, 1fr),
  table.header([*测试层次*], [*重点*], [*方法*]),
  [领域单元测试], [聚合不变量、状态机、策略、权限和补偿逻辑。], [不依赖 K8s 的快速测试。],
  [模块集成测试], [Repository、Outbox、Keycloak/Harbor/MinIO 适配器。], [容器化测试环境。],
  [集群契约测试], [Agent 协议、幂等、generation、断线恢复。], [多集群测试和故障注入。],
  [兼容测试], [ARM/x86、Ascend/CUDA、CANN/框架版本矩阵。], [目标硬件自检。],
  [安全测试], [越权、终端重放、网络隔离、构建逃逸、Secret 泄露。], [自动化 + 人工渗透。],
  [性能测试], [批量创建、镜像拉取、终端连接、数据库和存储。], [30 人并发场景压测。],
  [用户验收], [教师发布实验、学生完成实验、教师观察与恢复。], [真实课堂脚本。],
)

== 首期验收标准

- 30 个学生账户可通过课程批量导入并完成 OIDC 登录。
- 30 个工作区批量创建成功率不低于 95%，失败项可重试且无资源泄漏。
- CPU、ARM64 和 Ascend 310B 三类 ComputeProfile 可正确调度。
- 工作区停止后计算资源释放，重启后 `/workspace` 数据保持。
- 故障 Ascend 节点不会接受新任务，恢复后可重新纳入资源池。
- 教师可观察本人课程学生终端，其他课程访问被拒绝。
- 所有接管、重置、恢复、镜像发布和公网暴露操作具备审计记录。
- 镜像必须经过构建、扫描和目标环境自检后才能进入课程目录。
- 课程 Demo 可只读下发，学生可复制修改并一键恢复原始版本。
- 完成一次数据库恢复、PVC/工作区恢复和执行集群离线演练。
- 提供部署、运维、备份、故障处理、教师使用和学生使用文档。

== 阶段门

#table(
  columns: (25mm, 1fr, 1fr),
  table.header([*阶段门*], [*评审材料*], [*通过条件*]),
  [G0 立项], [章程、范围、预算口径、风险、采购计划], [发起人批准],
  [G1 架构], [DDD 模型、上下文地图、威胁模型、PoC], [架构与安全负责人批准],
  [G2 MVP], [功能演示、测试报告、缺陷清单], [P0 需求完成且无阻塞缺陷],
  [G3 试点上线], [容量、备份、监控、应急和培训], [上线检查表全部通过],
  [G4 验收], [试点数据、SLA、用户反馈、遗留问题], [验收委员会签署],
)

= 风险管理

== 风险登记册

#table(
  columns: (14mm, 1fr, 18mm, 18mm, 1fr, 30mm),
  table.header([*ID*], [*风险*], [*概率*], [*影响*], [*应对措施*], [*责任人*]),
  [R01], [Ascend 驱动、CANN、torch-npu 和镜像版本不兼容。], [高], [高], [建立兼容矩阵、固定 digest、目标硬件发布自检、保留已验证镜像。], [硬件专家],
  [R02], [SBC 稳定性、电源、散热或存储介质故障。], [中], [高], [主动散热、稳定电源、NVMe/eMMC、10%-20% 备用节点、资产监控。], [SRE],
  [R03], [学生长期占用 NPU 导致课堂资源不足。], [高], [高], [按需 Job、最长租约、空闲回收、课程队列和教师配额。], [计算域负责人],
  [R04], [终端观察引发隐私和权限争议。], [中], [高], [明确课程规则、学生提示、最小权限、审计、录像保留期和审批。], [PM/安全],
  [R05], [恶意 Dockerfile 或容器逃逸。], [中], [高], [独立 Rootless Builder、无 Docker Socket、策略扫描、网络和资源限制。], [安全/SRE],
  [R06], [单存储节点故障影响课程。], [中], [高], [试点前备份、备用恢复设备；正式阶段升级双机或分布式存储。], [SRE],
  [R07], [DDD 过度设计导致进度延迟。], [中], [中], [聚焦核心聚合和边界，避免一期微服务，ADR 控制抽象层级。], [架构/PM],
  [R08], [需求持续扩张形成“教学云平台”无限范围。], [高], [高], [范围基线、P0/P1/P2、阶段门和正式变更控制。], [PM],
  [R09], [缺少真实课堂数据导致容量误判。], [高], [中], [分批采购、记录并发、租约时长、镜像/存储增长和失败率。], [PM/SRE],
  [R10], [多集群 Agent 断线或命令重复产生资源泄漏。], [中], [高], [幂等键、generation、租约对账、补偿任务和周期 Reconcile。], [后端/SRE],
  [R11], [教师和学生学习成本过高。], [中], [中], [简化 ComputeProfile、提供模板、引导、自检和培训。], [产品/教师],
  [R12], [项目团队资源不足或关键人员单点。], [中], [高], [文档化、结对、代码评审、跨岗备份和优先级管理。], [PM],
)

== 风险阈值

任何“高概率 + 高影响”风险必须指定责任人、触发条件、应急计划和复审日期。触发后若可能影响里程碑超过 5 个工作日，应在 1 个工作日内上报项目发起人。

= 运维与服务管理

== 建议 SLO

#table(
  columns: (1fr, 1fr, 1fr),
  table.header([*服务指标*], [*试点目标*], [*说明*]),
  [门户/API 可用性], [99.5% / 月], [不含计划维护。],
  [课程时段终端连接成功率], [≥ 99%], [不含学生本地网络问题。],
  [工作区创建 P95], [≤ 3 分钟], [镜像已预热场景。],
  [工作区恢复 P95], [≤ 5 分钟], [普通软重置/已存在备份。],
  [P0 告警响应], [≤ 15 分钟], [课程时段值守。],
  [备份恢复演练], [每学期至少 1 次], [包括数据库与工作区样本。],
)

== 监控指标

- 控制面：API 延迟、错误率、队列、Outbox 堆积、数据库连接和事务。
- 工作区：状态分布、创建耗时、失败原因、空闲时长和存储配额。
- 算力：节点健康、租约、NPU/GPU 利用率、温度、显存/内存和任务排队。
- 终端：连接数、连接失败、会话时长、观察/接管和录像写入失败。
- 构建：队列时长、缓存命中、构建失败、扫描拒绝和存储增长。
- 存储：容量、IOPS、延迟、快照、备份和恢复结果。

== 运维文档

项目验收前应交付：部署手册、升级/回滚手册、集群接入手册、Ascend 节点安装和自检手册、镜像发布手册、备份恢复手册、课堂应急手册、权限审计手册、教师用户手册和学生快速入门。

= 成本与预算管理

== 预算结构

本方案不直接锁定单价，采购前应按学校采购流程询价。预算基线至少包含：

#table(
  columns: (33mm, 1fr, 1fr),
  table.header([*成本类别*], [*主要项目*], [*估算方法*]),
  [计算设备], [x86 服务器、Ascend SBC、CUDA 验证设备], [按角色配置、数量和 10%-20% 备用量。],
  [存储], [NVMe、HDD、NAS/存储服务器、备份介质], [按 3 年数据增长和 30% 空闲容量。],
  [网络与机房], [交换机、光模块、网卡、机架、PDU、UPS、散热], [按端口、带宽、功耗和冗余。],
  [软件与服务], [域名、证书、外部安全测试、云 GPU/备份（如需）], [按年度或使用量。],
  [人力], [研发、测试、平台、培训和试点支持], [按人月和阶段投入。],
  [风险预备金], [价格波动、备用设备、兼容整改], [建议为采购及外部服务的 10%-15%。],
)

== 预算控制

- 硬件采用分批采购，第二批以 G2/MVP 阶段门通过为前提。
- 新增计算设备应基于连续两周峰值利用率、排队时长和失败率数据。
- 存储扩容阈值建议为可用空间低于 30%，并提前评估垃圾回收和归档。
- 超过预算基线 10% 的变更必须提交变更审批。

= 变更、配置与文档管理

== 配置管理

- 所有平台配置和基础设施定义进入 Git 版本管理。
- 基础镜像、课程镜像、LabRelease 和 Demo 使用不可变版本/digest。
- 生产变更通过 Pull Request、自动测试和审批实施。
- 密钥、密码和 Token 不进入代码仓库，必须使用 Secret 管理。
- 领域事件、API 和 Agent 协议需进行版本管理和兼容策略说明。

== 变更请求模板

每项重大变更至少包含：变更原因、业务价值、范围影响、架构影响、安全影响、进度影响、预算影响、替代方案、回滚方案和审批人。

= 结论与决策请求

本项目具备明确教学价值和可执行的技术路径。推荐以 *DDD 模块化单体控制面 + 独立 Cluster Agent + 独立 Terminal Gateway + 独立 Build Worker + 多执行集群* 为架构基线，以集中 x86 控制/存储设施承载平台服务，以 Ascend SBC 形成可逐步扩展的教学计算池。

项目发起阶段请求批准以下事项：

1. 批准本设计方案作为需求和架构基线。
2. 批准 24 周试点实施计划和建议人员投入。
3. 批准开发验证档硬件优先采购或调配：1 台 x86 开发服务器、4-8 块 Ascend SBC、集中备份存储、可管理交换机和 UPS。
4. 同意在 M2 工作区闭环通过后，依据实测数据扩充至 12-16 块 SBC 和试点级基础设施。
5. 指定项目发起人、课程业务负责人、技术负责人和信息安全负责人。
6. 确认终端观察、录像保留、学生隐私和课程使用规则由教学管理方正式发布。

#callout(
  [最终推荐架构],
  [DDD 模块化单体控制面 + PostgreSQL Outbox + Keycloak + Harbor/MinIO + 多集群 Resource Broker + Cluster Agent + xterm.js Terminal Gateway + Rootless BuildKit。控制与存储运行在 x86 基础设施，Ascend SBC 作为受管执行池；高权限系统实验进入独立 VM 或隔离集群。],
  tone: "green",
)

#pagebreak()

= 附录 A：关键对象与 API 草案

== 关键对象

```text
User / IdentityLink
Course / ClassGroup / Enrollment
LabDefinition / LabRelease / LabPackage
ComputeProfile / ComputePool / Capability / ResourceLease
Workspace / WorkspaceInstance / StorageBinding
TerminalSession / Participant / RecordingReference
LabRun / LabStep / CheckResult / Submission
ImageBuild / ImageProfile / ScanResult / SelfTestResult
Checkpoint / ServiceDeployment / AuditEvent
```

== 外部 API 示例

```text
POST   /v1/courses
POST   /v1/courses/{id}/enrollments
POST   /v1/lab-releases

POST   /v1/workspaces
GET    /v1/workspaces/{id}
POST   /v1/workspaces/{id}:start
POST   /v1/workspaces/{id}:stop
POST   /v1/workspaces/{id}:reset
POST   /v1/workspaces/{id}:restore

POST   /v1/terminal-sessions
POST   /v1/builds
GET    /v1/compute-profiles
POST   /v1/service-deployments
GET    /v1/courses/{id}/progress
```

所有写 API 应支持幂等键、关联 ID、审计主体和明确的错误代码。

= 附录 B：待确认事项

#table(
  columns: (14mm, 1fr, 1fr, 27mm),
  table.header([*ID*], [*待确认问题*], [*影响*], [*责任角色*]),
  [O-01], [课程首期人数、峰值同时在线和并发 NPU 的真实目标。], [决定 SBC、存储和网络规模。], [课程负责人],
  [O-02], [现有 Orange Pi AiPro 板卡数量、内存、存储和 CANN/驱动版本。], [决定兼容矩阵和采购缺口。], [硬件负责人],
  [O-03], [学校是否已有统一身份认证及 OIDC/SAML 接入条件。], [决定 Keycloak 代理和临时账户流程。], [信息中心],
  [O-04], [终端录像是否必须、保留多久、谁可查看。], [影响隐私、合规和存储。], [教学/安全],
  [O-05], [是否需要支持内核模块、Docker daemon 等高权限实验。], [决定 VM/KubeVirt 或独立集群范围。], [课程负责人],
  [O-06], [是否已有 NAS、10 GbE、机架和 UPS。], [决定采购预算。], [实验室],
  [O-07], [CUDA 是正式教学资源还是仅兼容性验证。], [决定 GPU 采购或云资源。], [项目发起人],
  [O-08], [试点上线时间及学校采购周期。], [决定关键路径和分批交付。], [项目经理],
)

#v(18pt)
#align(center)[
  #text(size: 9pt, fill: colors.muted)[— 文档结束 —]
]
