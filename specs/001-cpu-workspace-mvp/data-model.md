# Phase 1 Data Model: 昇腾算子远程实训平台一期 MVP

## 领域边界与事务

`Workspace`、`TaskWorkspace` 和 `Class` 分别是其行为的聚合根；Identity、Authorization、Terminal 与
Audit/Outbox 是相邻上下文。任何触发运行时、存储、导出或清理的命令，在一个事务内写入授权结果、
aggregate 版本/generation、Operation、Audit Record 与 Outbox Event；外部调用始终由 Worker 处理。

## DDD 聚合、所有权与事件

| 上下文 | 聚合根 | 内聚不变量 | 对外发布的事实 |
|---|---|---|---|
| Identity | User | 外部 subject 一对一映射；邮箱非权威 | `UserIdentityResolved` |
| Authorization | Role、Permission、RoleBinding | 授权必须具有平台或班级范围 | `RoleBindingChanged` |
| Class | Class、ClassMembership | 成员/额度/Profile 启用均按班级隔离 | `MembershipChanged`、`ClassQuotaChanged` |
| Workspace | Workspace、WorkspaceVolume、WorkspaceOperation | 名称唯一、单冲突操作、generation 单调递增 | `WorkspaceOperationRequested`、`WorkspaceObserved` |
| Task | LongRunningTask、TaskWorkspace、TaskGrant | 任务卷/授权永不复用学生资源 | `TaskOperationRequested`、`TaskGrantChanged` |
| Terminal | TerminalRecord | 先过滤再可见/归档，班级范围不可突破 | `TerminalCaptureGapObserved` |
| Audit | AuditRecord、OutboxEvent | 关键允许、拒绝与处置必须有证据 | 版本化 Outbox 事件 |

事件是不可变集成事实；它们只携带稳定标识、版本、关联/追踪信息和最小必要状态，不携带令牌、Cookie、
设备路径、K3s 类型或完整终端敏感内容。跨上下文写入由应用服务编排，不能让一个聚合直接修改另一个聚合。

## 实体与关系

| 实体 | 核心属性 | 关键规则 |
|---|---|---|
| User | `id`, `externalSubject`, status, displayName | `externalSubject` 全局唯一；邮箱只用于显示或联系。 |
| Class | `id`, name, status, trainingPeriod, quotaPolicy | 最小资源/日志/权限隔离边界。 |
| ClassMembership | `classId`, `userId`, status, effectiveScope | 决定成员资格；变更必须审计。 |
| Role / Permission / RoleBinding | stable ID, definition, scope, status | 角色、权限及平台/班级范围绑定可管理；不能替代资源所有权。 |
| WorkspaceProfile | `id`, version, computeKind, approvalStatus, limits | `CPU` 或 `ASCEND_NPU`；平台批准、班级启用；用户不可修改限制或能力。 |
| ClassProfileEnablement | `classId`, `profileId`, quota policy, status | 决定该班级可用配置和独立 CPU/NPU 额度。 |
| Workspace | `id`, `classId`, `ownerId`, name, state, generation, volumeId | 一个班级、一个所有者；未删除和创建中的名称对同一 owner/class 唯一。 |
| WorkspaceVolume | `id`, `classId`, `ownerId`, binding/retention state, capacity | 只能重绑到同班级、同所有者工作区；计入班级额度。 |
| WorkspaceOperation | `id`, target ID, type, status, generation, idempotency/retry fields | 可追踪、可安全显示失败、与 audit/outbox/trace 关联。 |
| TerminalOperationRecord | scope, actor/workspace/task, direction, time, filtered payload | 仅保存过滤后的内容；采集缺口同样可查询。 |
| LongRunningTask | `id`, `classId`, requester, profile snapshot, state | 仅控制面任务；不表示服务端点。 |
| TaskWorkspace / TaskGrant | task ID, independent volume, generation, subject/action/status | 与学生工作区分离；授权可撤销且有审计。 |
| AuditRecord / OutboxEvent | actor/action/target/outcome/correlation; event metadata | 与状态变更同事务持久化；Outbox 可靠分发。 |

## 配额与资源不变量

1. CPU、Ascend NPU、存储和任务资源分别以班级额度核算；NPU 还须预留受控节点槽位。
2. 每个可用 NPU 节点的同时运行工作区上限为 3；编译并发使用单独队列，不能借由普通工作区配额绕过。
3. NPU 资源不足、节点不健康或配置未启用时，操作可等待或失败，但绝不自动转换为 CPU。
4. Profile 普通停用仅阻止新创建；安全/合规撤销终止未完成相关创建并进入清理协调。
5. 用户、班级、任务和卷的每个查询都以 class scope 过滤；无权请求返回不泄露存在性的结果。

## 工作区状态机

```text
不存在 → 创建等待 → 准备中 → 运行中 → 停止中 → 已停止
                    └──────→ 失败 / 待协调

运行中、已停止、可恢复失败 → 重置中 → 运行中 / 失败
运行中、已停止、可恢复失败 → 删除中 → 已删除 / 待协调
```

| 命令 | 允许来源 | 成功目标 | 数据语义 |
|---|---|---|---|
| Create | 不存在 | 运行中或明确失败 | 新建或绑定符合归属的卷。 |
| Start | 已停止 | 运行中 | 重用卷。 |
| Stop | 运行中/准备中 | 已停止 | 释放运行资源，保留卷。 |
| Reset | 运行中/已停止/可恢复失败 | 运行中 | 重建非持久运行内容，保留卷。 |
| Delete keep-data | 非已删除 | 已删除 | 解绑、保留卷和配额影响。 |
| Delete delete-data | 非已删除 | 已删除 | 删运行资源及卷；卷失败时操作继续自动重试。 |

每个改变运行状态的命令递增 generation。Operation 状态为 `pending`、`running`、`succeeded`、
`failed` 或 `reconciling`；同一工作区不能存在冲突的未终态操作。重复请求返回原 Operation；显式可恢复
重试生成关联的新 Operation。旧 generation 的观察结果不得写回当前状态。

## 培训期与长期任务

培训期结束事务创建班级处置 Operation：停止学生工作区、保留卷、限制学生新操作；教师/授权管理员可
导出资料，只有授权管理员可开始最终清理。导出与清理各自有状态、失败和审计，不能将数据处置伪报成功。

`LongRunningTask` 使用独立 `TaskWorkspace`、任务卷和 TaskGrant。其创建、取消、恢复、分配与撤销遵循
同样的 Operation/Outbox/generation 规则；Task Workspace 永不绑定学生 Workspace 或学生 Volume，任务
终端记录也不进入学生记录范围。

## 迁移与兼容要求

数据库迁移使用 expand-migrate-contract：先添加兼容字段/表与回填，再切换读写，最后在兼容窗口后删除
旧结构。每个迁移必须记录锁与语句超时、事务模式、表扫描/重写风险、验证查询和 roll-forward 恢复。旧
Project/CPU-only 草案未发布，不生成双模型；在实现前统一采用 Class 和 CPU/NPU 模型。
