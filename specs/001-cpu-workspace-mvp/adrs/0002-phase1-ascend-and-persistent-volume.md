# ADR-0002：一期 CPU/Ascend 运行时与独立持久卷

- **状态**：已接受
- **日期**：2026-07-23
- **决策范围**：一期运行时适配、NPU 准入、持久数据和长期任务隔离

## 背景

一期同时需要 CPU 与昇腾 NPU 工作区、单节点受控部署、训练期数据连续性及长期任务隔离。直接将 K3s、
Ascend device-share 或共享存储参数加入领域模型或公开 API，会破坏可移植性和租户安全边界。

## 决策

1. 使用统一领域 `WorkspaceRuntime`/Volume 端口与 `ComputeRequirement(CPU|ASCEND_NPU)`；K3s、CANN、
   device-share 资源键、注解、设备路径和存储挂载细节仅由 Adapter 持有。
2. CPU/NPU 共享生命周期、Operation、Outbox、generation 和 Volume 语义；班级配额、节点槽位、
   调度资格、统计和并发规则独立核算。每个 NPU 节点一期最多 3 个受控 NPU 工作区，编译使用受控队列。
3. `WorkspaceVolume` 与运行实例独立，按 class/owner/volume 身份管理；任务工作区使用独立任务卷与
   Task Grant，不读取或复用学生工作区、卷或终端记录。
4. Ascend Adapter 的具体映射仅在目标 8T/20T 硬件、目标镜像与 device-share 集成验证通过后冻结；失败
   请求返回可追踪等待/失败，绝不降级为 CPU。

## 后果

* 领域、控制面契约和前端不依赖具体硬件资源名称；可在未来新增设备 Adapter。
* 必须实施 NPU 准入、节点槽位/编译队列、8T/20T 集成测试和独立卷权限测试。
* 存储/运行时部分成功需由 Worker 协调；删卷失败保持 Operation 执行并自动重试。

## 替代方案

* 公开 K3s/Ascend 参数：拒绝，供应商实现泄露且契约脆弱。
* 通过 HostPath、socket 或特权容器访问设备/数据：拒绝，违反宪法隔离规则。
* 复用学生工作区执行长期任务：拒绝，无法满足独立数据与授权边界。

## 兼容与恢复

该 ADR 定义未发布一期模型，取代旧 CPU-only 规划前提。后续 Profile、状态或持久数据语义改变必须更新
契约、提供迁移与 roll-forward 恢复说明。运行时或存储调用超时后，以稳定 ID 和 generation 对账，而非
盲目重复创建。
