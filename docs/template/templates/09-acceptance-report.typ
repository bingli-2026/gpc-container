#import "../project-kit.typ": *

#show: project-document.with(
  title: "项目验收报告",
  subtitle: "核对范围、质量、运行准备和遗留事项，形成正式验收结论",
  doc-type: "PROJECT ACCEPTANCE REPORT",
  version: "V1.0",
  date: "待填写",
  organization: "待填写",
  owner: "项目经理",
  toc: true,
)

= 验收摘要

#metric-grid((
  metric-card([交付物完成], [12/12], detail: [全部提交]),
  metric-card([验收用例通过], [98%], detail: [2 项有条件通过], tone: "green"),
  metric-card([遗留问题], [3], detail: [无阻塞问题], tone: "amber"),
))

#v(8pt)
#callout([建议结论], [建议“有条件通过”，遗留事项按本报告约定期限关闭。], tone: "teal")

= 验收范围与依据

填写项目章程、合同/任务书、需求基线、批准的变更和验收计划。

= 交付物验收

#deliverable-table((
  ([D01], [软件/系统交付], [研发负责人], [待填写], [功能和测试报告], status-badge("通过")),
  ([D02], [部署与运维文档], [SRE], [待填写], [文档评审和演练], status-badge("通过")),
  ([D03], [培训与移交], [项目经理], [待填写], [签到和反馈], status-badge("有条件通过")),
))

= 验收标准结果

#data-table(
  ([编号], [验收标准], [结果], [证据], [备注]),
  (
    ([AC-01], [核心功能全部通过], status-badge("通过"), [测试报告链接/编号], []),
    ([AC-02], [性能达到目标], status-badge("通过"), [压测报告], []),
    ([AC-03], [备份恢复演练通过], status-badge("有条件通过"), [演练记录], [需补充一次全量演练]),
  ),
  columns: (17mm, 1fr, 27mm, 1fr, 1fr),
)

= 运行准备度

#checklist((
  (true, [生产环境和监控已部署。]),
  (true, [备份、告警和应急联系人已配置。]),
  (false, [剩余运维人员培训已完成。]),
  (true, [管理员、教师和用户手册已交付。]),
))

= 遗留事项

#action-table((
  ([A01], [遗留事项一及关闭标准], [负责人], [YYYY-MM-DD], status-badge("进行中")),
  ([A02], [遗留事项二及关闭标准], [负责人], [YYYY-MM-DD], status-badge("待开始")),
))

= 验收结论

□ 通过　　□ 有条件通过　　□ 不通过

说明结论、生效日期、质保/支持安排、遗留事项责任和项目收尾条件。

= 签署

#signature-table(rows: ([项目经理], [业务负责人], [技术负责人], [项目发起人]))
