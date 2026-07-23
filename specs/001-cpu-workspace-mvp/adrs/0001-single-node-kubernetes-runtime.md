# ADR-0001：一期工作区采用单节点 Kubernetes Runtime Adapter

**状态**：已接受
**日期**：2026-07-22
**关联规格**：[昇腾算子远程实训平台一期 MVP](../spec.md)

## 决策

一期 CPU 与昇腾 NPU 工作区通过 `WorkspaceRuntime` 领域端口接入单节点 Kubernetes。领域、应用服务、
HTTP 契约和 Next.js BFF 只使用工作区、卷、Profile、算力需求、资源限制、operation ID 与 generation
等平台术语；Kubernetes 对象、Ascend device-share 类型和 SDK 类型仅位于 Runtime Adapter 内。

持久数据作为独立的 Workspace Volume 管理，而不是仅作为 Workspace 的运行时引用。适配器为每个
运行时操作使用 `workspaceId + generation + operation` 的幂等标识，并支持 inspect/reconciliation。

## 背景

一期需要单节点 CPU/NPU 工作区的完整生命周期、独立持久数据和可恢复的异步操作。系统宪法禁止暴露
Docker/runtime socket、HostPath、host networking 和特权工作负载，同时要求运行时类型不侵入领域。

## 后果

- 运行时适配器必须创建非 root、非特权且有明确 CPU/内存/存储/设备限制的受控工作负载。
- Ascend NPU 映射仅在 Adapter 内部实现；须在 8T/20T 目标环境验证隔离、独立配额和每节点 3 个
  NPU 工作区并发，且不得静默降级为 CPU。
- Worker 必须在调用适配器前持久化 Outbox 意图，并在超时、重启、重复投递或部分成功后协调观测状态。
- 后续 Docker、Cluster Agent 或多集群实现只能新增同一端口的适配器；不得修改已发布的工作区、
  operation、volume 或权限语义。
- 适配器集成测试必须在单节点 Kubernetes 测试环境验证创建、停止、默认重置、删除、持久卷策略、
  generation 与故障协调。

## 备选方案

- **Docker Runtime Adapter**：不作为首批实现，以避免将 runtime socket 或宿主机权限引入控制面。
- **多集群 Agent**：适用于后续扩展，但超出单节点 MVP 的部署和恢复范围。
- **在领域中直接使用 Kubernetes 类型**：违反依赖方向与可替换运行时要求。
