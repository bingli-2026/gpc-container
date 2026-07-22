#import "../project-kit.typ": *

#show: project-document.with(
  title: "项目周报",
  subtitle: "第 XX 周 · YYYY-MM-DD 至 YYYY-MM-DD",
  doc-type: "WEEKLY STATUS",
  version: "WXX",
  date: "待填写",
  organization: "待填写",
  owner: "项目经理",
  cover: false,
  toc: false,
)

#document-title(
  [项目周报],
  subtitle: [第 XX 周 · YYYY-MM-DD 至 YYYY-MM-DD],
  meta: [项目：待填写　|　项目经理：待填写　|　报告日期：待填写],
)

#v(10pt)
#metric-grid((
  metric-card([总体状态], [正常], detail: [范围、进度和成本可控], tone: "green"),
  metric-card([计划完成率], [82%], detail: [本周 9/11 项完成]),
  metric-card([高风险/阻塞], [1 / 1], detail: [需要管理层协助], tone: "amber"),
))

= 管理摘要

#callout([本周结论], [填写一段面向管理层的摘要：进展、偏差、关键风险和需要的决策。], tone: "teal")

= 进度健康度

#progress-bar(percent: 82%, label: [本周计划完成率], tone: "green")
#v(7pt)
#progress-bar(percent: 65%, label: [总体项目完成度], tone: "blue")

= 本周完成

- 完成事项一，说明产生的结果，而非仅描述活动。
- 完成事项二。
- 完成事项三。

= 下周计划

#action-table((
  ([A01], [下周计划一], [张三], [YYYY-MM-DD], status-badge("进行中")),
  ([A02], [下周计划二], [李四], [YYYY-MM-DD], status-badge("待开始")),
))

= 风险与阻塞

#risk-register((
  ([R01], [风险描述], [中], [高], [应对措施和升级条件], [负责人], status-badge("关注")),
))

#v(8pt)
#issue-table((
  ([I01], [阻塞问题], [影响某里程碑], [负责人], [YYYY-MM-DD], status-badge("阻塞")),
))

= 需要决策/支持

#decision-table((
  ([D01], [需要管理层决定的事项], [建议选择及影响], [待决策], [YYYY-MM-DD]),
))
