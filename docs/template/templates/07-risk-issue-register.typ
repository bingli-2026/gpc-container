#import "../project-kit.typ": *

#show: project-document.with(
  title: "项目风险与问题登记册",
  subtitle: "持续识别、评估、应对和升级项目不确定性",
  doc-type: "RISK & ISSUE REGISTER",
  version: "V1.0",
  date: "待填写",
  organization: "待填写",
  owner: "项目经理",
  cover: false,
  toc: false,
)

#document-title(
  [项目风险与问题登记册],
  meta: [项目：待填写　|　更新时间：待填写　|　责任人：项目经理],
)

#v(8pt)
#metric-grid((
  metric-card([开放风险], [6], detail: [其中高风险 2 项], tone: "amber"),
  metric-card([开放问题], [3], detail: [其中阻塞 1 项], tone: "red"),
  metric-card([本周关闭], [2], detail: [均已验证措施有效], tone: "green"),
))

= 风险登记册

#risk-register((
  ([R01], [描述尚未发生但可能发生的事件], [中], [高], [预防措施、应急方案和触发条件], [负责人], status-badge("关注")),
  ([R02], [第二项风险], [低], [中], [接受/降低/转移/规避措施], [负责人], status-badge("正常")),
))

= 问题登记册

#issue-table((
  ([I01], [已经发生并影响交付的问题], [影响说明], [负责人], [YYYY-MM-DD], status-badge("阻塞")),
  ([I02], [第二项问题], [影响说明], [负责人], [YYYY-MM-DD], status-badge("进行中")),
))

= 复审与升级规则

- 高概率且高影响风险必须具有触发条件、应急计划和责任人。
- 预计影响关键路径超过 5 个工作日的问题需在 1 个工作日内升级。
- 关闭风险或问题前必须验证措施结果并记录证据。
