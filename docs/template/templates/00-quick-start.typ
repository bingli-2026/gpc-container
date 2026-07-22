#import "../project-kit.typ": *
// 安装到本地包目录后，也可以改为：
// #import "@local/project-kit:0.1.0": *

#show: project-document.with(
  title: "项目文档标题",
  subtitle: "一句话说明文档目的",
  doc-type: "PROJECT DOCUMENT",
  version: "V0.1",
  date: "2026-07-22",
  organization: "某某单位",
  owner: "项目负责人",
  toc: true,
)

= 执行摘要

#metric-grid((
  metric-card([计划周期], [12 周], detail: [从立项到验收]),
  metric-card([项目状态], [正常], detail: [总体按计划推进], tone: "green"),
  metric-card([当前阶段], [设计], detail: [正在完成技术基线], tone: "teal"),
))

#v(8pt)
#callout([管理建议], [在这里填写面向决策人的结论、选择和所需批准。], tone: "teal")

= 项目概述

== 背景

填写背景、问题、机会和项目必要性。

== 目标

- 目标一。
- 目标二。
- 目标三。

= 计划与交付

#milestone-table((
  ([M1 需求基线], [2026-08-01], [张三], [需求和范围获批], status-badge("完成")),
  ([M2 原型评审], [2026-09-01], [李四], [核心流程可演示], status-badge("进行中")),
  ([M3 项目验收], [2026-10-30], [王五], [验收标准全部通过], status-badge("待开始")),
))
