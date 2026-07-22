#import "../project-kit.typ": *

#show: project-document.with(
  title: "系统设计报告",
  subtitle: "需求、架构、领域模型、数据、安全与实施设计",
  doc-type: "SYSTEM DESIGN REPORT",
  version: "V1.0",
  date: "待填写",
  organization: "待填写",
  owner: "技术负责人",
  toc: true,
)

= 执行摘要

#metric-grid((
  metric-card([设计状态], [基线评审], detail: [等待架构委员会批准]),
  metric-card([关键决策], [3 项], detail: [详见 ADR], tone: "teal"),
  metric-card([高风险], [1 项], detail: [已制定验证计划], tone: "amber"),
))

#v(8pt)
#callout([架构结论], [用一段话说明推荐设计、关键取舍、当前限制和所需决策。], tone: "teal")

= 背景、目标与范围

填写业务背景、技术目标、范围内、范围外、假设和约束。

= 需求与质量属性

#data-table(
  ([ID], [质量属性], [场景], [目标]),
  (
    ([NFR-01], [可用性], [单节点故障], [核心服务不受影响]),
    ([NFR-02], [性能], [典型请求], [P95 < 1 s]),
    ([NFR-03], [安全], [跨租户访问], [全部拒绝并审计]),
  ),
  columns: (18mm, 27mm, 1fr, 1fr),
)

= 领域与模块设计

#grid(
  columns: (1fr, 10mm, 1fr, 10mm, 1fr),
  align: center + horizon,
  architecture-node([入口层], [Web、API Gateway、OIDC]),
  flow-arrow(),
  architecture-node([应用/领域层], [用例、聚合、策略、领域事件], tone: "teal"),
  flow-arrow(),
  architecture-node([基础设施层], [数据库、消息、外部系统适配器], tone: "purple"),
)

== 领域模型

说明限界上下文、聚合、实体、值对象、领域服务和不变量。

== 关键流程

```text
Command -> Application Service -> Aggregate
        -> Repository + Outbox -> Event Handler
        -> External Adapter / Process Manager
```

= 数据设计

填写数据分类、表/实体关系、一致性模型、生命周期、备份和迁移策略。

= 接口设计

#data-table(
  ([接口], [调用方], [用途], [鉴权], [幂等]),
  (
    ([POST /v1/resources], [门户], [创建资源], [OIDC Scope], [Idempotency-Key]),
    ([Agent.Command], [控制面], [下发集群命令], [mTLS], [command_id]),
  ),
  columns: (35mm, 28mm, 1fr, 31mm, 31mm),
)

= 安全设计

填写信任边界、身份、授权、密钥、网络隔离、审计、威胁模型和安全测试。

= 部署、容量与可观测

说明物理部署、容量估算、SLO、日志、指标、追踪、告警和恢复。

= 架构决策记录

#decision-table((
  ([ADR-001], [部署形态], [首期采用模块化单体], [架构委员会], [待填写]),
  ([ADR-002], [异步一致性], [PostgreSQL Outbox], [技术负责人], [待填写]),
))

= 风险与验证计划

#risk-register((
  ([R01], [关键组件性能未知], [中], [高], [构建压力测试和容量基线], [性能负责人], status-badge("关注")),
))
