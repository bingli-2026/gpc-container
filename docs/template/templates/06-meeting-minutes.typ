#import "../project-kit.typ": *

#show: project-document.with(
  title: "会议纪要",
  subtitle: "用于记录事实、决策、行动项和待确认问题",
  doc-type: "MEETING MINUTES",
  version: "V1.0",
  date: "待填写",
  organization: "待填写",
  owner: "记录人",
  cover: false,
  toc: false,
)

#document-title(
  [会议纪要：会议主题],
  meta: [日期：待填写　|　时间：待填写　|　地点/链接：待填写　|　主持人：待填写],
)

#v(8pt)
#info-table((
  ([*会议类型*], [项目例会/评审/决策会], [*记录人*], [待填写]),
  ([*参会人员*], [待填写], [*缺席人员*], [待填写]),
  ([*会议目标*], [待填写], [*关联项目*], [待填写]),
))

= 议程

1. 议题一。
2. 议题二。
3. 议题三。

= 讨论摘要

== 议题一

记录事实、不同观点、依据和结论。避免把未达成一致的内容写成正式决策。

== 议题二

记录讨论摘要。

= 已确认决策

#decision-table((
  ([D01], [决策事项], [明确的决策结果及生效范围], [决策人], [待填写]),
))

= 行动项

#action-table((
  ([A01], [具体、可验证的行动项], [负责人], [YYYY-MM-DD], status-badge("进行中")),
  ([A02], [行动项二], [负责人], [YYYY-MM-DD], status-badge("待开始")),
))

= 待确认问题

#issue-table((
  ([Q01], [需要进一步确认的问题], [影响范围], [负责人], [YYYY-MM-DD], status-badge("待确认")),
))

= 下次会议

时间、主题、所需输入材料和必须参会人员。
