#import "../project-kit.typ": *

#show: project-document.with(
  title: "Project Kit 组件展示",
  subtitle: "复制组件调用即可快速构建项目文档",
  doc-type: "COMPONENT SHOWCASE",
  version: "0.1.0",
  date: "2026-07-22",
  organization: "Project Kit",
  owner: "Template User",
  toc: true,
)

= 标签与提示

#grid(
  columns: (auto, auto, auto, auto, auto),
  gutter: 6pt,
  status-badge("正常"),
  status-badge("进行中"),
  status-badge("阻塞"),
  priority-badge("P0"),
  priority-badge("P2"),
)

#v(8pt)
#callout([信息提示], [适合写结论、背景、说明和一般提醒。])
#v(6pt)
#callout([风险提示], [适合写风险、偏差和需要关注的问题。], tone: "warning")
#v(6pt)
#callout([关键告警], [适合写阻塞、重大安全问题和必须升级的事项。], tone: "danger")

= 指标与进度

#metric-grid((
  metric-card([项目周期], [24 周], detail: [从立项到验收]),
  metric-card([总体状态], [正常], detail: [无重大偏差], tone: "green"),
  metric-card([开放风险], [3], detail: [其中高风险 1 项], tone: "amber"),
))

#v(10pt)
#progress-bar(percent: 72%, label: [总体完成度])
#v(6pt)
#progress-bar(percent: 45%, label: [本阶段完成度], tone: "teal")

= 常用管理表格

== 里程碑
#milestone-table((
  ([M1 需求基线], [2026-08-01], [张三], [需求和验收标准批准], status-badge("完成")),
  ([M2 MVP], [2026-10-01], [李四], [P0 功能上线], status-badge("进行中")),
))

== 行动项
#action-table((
  ([A01], [完成接口评审], [王五], [2026-08-05], status-badge("进行中")),
))

== 风险
#risk-register((
  ([R01], [外部依赖延期], [中], [高], [Mock 先行并设置升级路径], [赵六], status-badge("关注")),
))

== RACI
#raci-table(
  ([活动], [发起人], [PM], [业务], [技术], [研发]),
  (([需求批准], [A], [R], [R], [C], [I]),),
)

= 架构节点

#grid(
  columns: (1fr, 10mm, 1fr, 10mm, 1fr),
  align: center + horizon,
  architecture-node([前端], [Web 门户与终端]),
  flow-arrow([HTTPS]),
  architecture-node([控制面], [领域模块与工作流], tone: "teal"),
  flow-arrow([mTLS]),
  architecture-node([执行集群], [Kubernetes 与硬件适配], tone: "purple"),
)

= 清单与签署

#checklist((
  (true, [需求评审已完成。]),
  (false, [安全测试已完成。]),
  (false, [上线审批已完成。]),
))

#signature-table()
