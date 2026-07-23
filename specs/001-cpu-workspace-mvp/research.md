# Phase 0 Research: 昇腾算子远程实训平台一期 MVP

## 1. 控制面、班级与 RBAC

**Decision**: 采用 Go 模块化单体控制面，划分 Identity、Authorization、Class、Workspace、
Terminal、Task 与 Audit/Outbox 上下文。`Class` 取代旧 `Project`，是成员、配额、配置、资源、
终端记录和审计的最小隔离边界；角色、权限和范围绑定为可管理资源。

**Rationale**: 班级而非前端路由或固定角色枚举，才能同时表达教师、助教、学生、查看者、资源所有者和
后续委派职责。领域规则不依赖 K3s、数据库或浏览器对象。

**Alternatives considered**:

- 保留 Project 并将 Class 作为展示名称：拒绝，会让隔离语义和契约迁移长期混乱。
- 仅用固定角色枚举：拒绝，不能满足角色/权限/绑定管理与范围授权。

## 2. CPU 与 Ascend NPU 运行时

**Decision**: 建立单一 `WorkspaceRuntime` 端口，以领域级 `ComputeRequirement` 和批准 Profile 表达
`CPU` 或 `ASCEND_NPU`。K3s、Ascend device-share、资源名、注解、设备路径和厂商 SDK 仅存在于
Ascend Runtime Adapter 内。CPU/NPU 共享工作区、操作、generation、卷和生命周期语义，但班级配额、
调度资格、统计与准入分别核算。

**Rationale**: 满足领域与基础设施隔离，并可在 8T/20T 混合节点下保持一致的用户体验。NPU 创建时先
原子预留班级 NPU 配额与节点槽位；每节点上限为 3 个受控 NPU 工作区，编译并发另由受控队列管理。

**Alternatives considered**:

- 将 K3s/Ascend 资源字段暴露到公开 API：拒绝，泄露供应商实现并使契约无法演进。
- 以 HostPath、设备 socket 或特权模式实现：拒绝，违反宪法工作负载隔离。
- 一期引入 vNPU/HAMi：拒绝，明确为后续范围。

**Validation decision**: 目标镜像、CANN、K3s 与 device-share 的 8T/20T 资源发现、隔离和三并发
必须先以 Adapter 集成验证固化；不在计划中猜测具体资源键或插件参数。

## 3. 持久数据与培训期处置

**Decision**: `WorkspaceVolume` 是独立聚合，由存储 Adapter 管理。逻辑归属为 class、owner 与 volume
标识，运行实例只能得到其受控卷；用户不能提供任意共享存储路径。停止/启动/默认重置保留卷；删除时
明确保留或删除。任务卷使用独立 volume identity 和访问策略。

**Rationale**: 支持重新绑定、配额核算、离班处置和删除失败恢复，也避免使用容器文件系统或 HostPath。
控制面是卷归属、绑定、保留与配额的权威记录，存储服务不是权威控制数据源。

**Alternatives considered**:

- 将学生数据放入容器文件系统：拒绝，停止/重置和节点故障会破坏连续性。
- 允许客户端提交共享存储路径：拒绝，产生跨班级路径与权限绕过风险。
- 让任务工作区共享学生卷：拒绝，违反 FR-024。

## 4. 异步操作与协调恢复

**Decision**: 所有外部副作用在单一数据库事务中持久化意图、授权结果、aggregate transition、
generation、operation、audit 和 Outbox；Worker 执行外部调用，以 `workspaceId + generation + operation`
或 Task Workspace 的等价键对账。外部 effect 命令统一返回 `202 Accepted` 和不可变操作 ID。

**Rationale**: 能处理重复请求、消息重复、超时、部分成功和重启，且确保旧结果不会覆盖新代次。

**Alternatives considered**:

- API 同步等待运行时：拒绝，无法安全覆盖慢操作和连接丢失。
- 内存队列：拒绝，进程崩溃会丢失已接受命令。

## 5. 终端采集与教学证据

**Decision**: 终端采集作为独立 Adapter，接收 WebIDE 和 SSH（含 VS Code Remote-SSH）的会话元数据、
输入、stdout、stderr、时间和关联标识；在实时可见、检索和归档前过滤预定义敏感片段。采集记录以
class/user/workspace/task scope 分隔；采集缺口也作为运营证据。

**Rationale**: 教师需要过程可见性，但不应借由日志获得跨班级访问或敏感凭证。采集失败不阻塞安全关闭，
但必须告警和可查询。

**Alternatives considered**:

- 仅记录命令历史：拒绝，无法满足输出和错误追踪。
- 将原始记录无差别开放给教师：拒绝，违反最小授权与敏感信息规则。

## 6. 长期任务边界

**Decision**: 建模 `LongRunningTask` 与 `TaskWorkspace`。任务拥有独立的生命周期、操作、卷、
配额保留和可撤销 Task Grant；提交 API 仅接收班级范围、批准 Task Profile、受控输入引用和幂等键。
任务本身不得包含服务端点、Ingress、任意环境变量或服务发布能力。

**Rationale**: 避免把学生个人工作区、卷或终端记录当作任务数据通道，并保持任务可追踪和可审计。

**Alternatives considered**:

- 复用学生工作区或数据卷：拒绝，隔离和所有权不成立。
- 只检查班级成员资格：拒绝，任务还需要独立范围授权。
- 让长期任务暴露 API：拒绝，一期非目标。

## 7. 契约、前端与运营

**Decision**: 以单份版本化 OpenAPI 3.1 文档定义身份、班级、RBAC、Profile/额度、工作区/卷、操作、
终端、培训期、任务、审计及健康接口。前端原型在该契约冻结后更新为班级切换、CPU/NPU、教学过程、
角色绑定、培训期处置、长期任务和每页/弹窗独立设计图。

**Rationale**: 现有 Project/CPU-only 契约和原型未发布，直接统一替换可避免双路径兼容负担；若出现
消费者，则应发布新版本并给出迁移窗口。

**Alternatives considered**:

- 在旧 Project API 上追加 Class 字段：拒绝，会保留相互冲突的授权模型。
- 前端自行推断权限或操作状态：拒绝，权威结果必须来自控制面。

## 8. Multi-Tenant 试点门槛

**Decision**: 试点开放前完成默认拒绝网络暴露、双班级授权/契约测试、班级与用户额度、访问拒绝审计、
备份恢复验证、生命周期指标/告警、管理员代操作政策与凭证轮换流程。

**Rationale**: 一期虽然是受控单节点，却会服务无关班级，必须满足宪法 Multi-Tenant Gate。

**Alternatives considered**:

- 将多班级仅当作演示而绕过门槛：拒绝，隔离失效会造成真实数据暴露风险。
