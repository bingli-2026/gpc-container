# Project Kit 常用函数速查

导入：

```typst
#import "../project-kit.typ": *
// 或
#import "@local/project-kit:0.1.0": *
```

## 文档框架

```typst
#show: project-document.with(
  title: "项目标题",
  subtitle: "副标题",
  doc-type: "PROJECT REPORT",
  version: "V1.0",
  date: "2026-07-22",
  organization: "单位",
  owner: "负责人",
  cover: true,
  toc: true,
)
```

短文档标题：

```typst
#document-title(
  [项目周报],
  subtitle: [第 12 周],
  meta: [项目：A | 日期：2026-07-22],
)
```

## 标签

```typst
#badge([自定义], tone: "purple")
#status-badge("正常")
#status-badge("进行中")
#status-badge("阻塞")
#priority-badge("P0")
```

## 提示块与指标

```typst
#callout([管理建议], [正文], tone: "teal")
#metric-card([总体状态], [正常], [无重大偏差], tone: "green")
#metric-grid((
  metric-card([周期], [12 周]),
  metric-card([风险], [2], tone: "amber"),
  metric-card([完成度], [72%]),
))
#progress-bar(percent: 72%, label: [总体完成度])
```

## 通用表格

```typst
#data-table(
  ([列一], [列二]),
  (
    ([值一], [值二]),
    ([值三], [值四]),
  ),
  columns: (1fr, 1fr),
)
```

## 项目管理表格

```typst
#milestone-table((
  ([M1], [2026-08-01], [张三], [退出条件], status-badge("进行中")),
))

#action-table((
  ([A01], [行动项], [李四], [2026-08-05], status-badge("待开始")),
))

#decision-table((
  ([D01], [决策事项], [决策结果], [王五], [2026-07-22]),
))

#issue-table((
  ([I01], [问题], [影响], [赵六], [2026-08-10], status-badge("阻塞")),
))

#risk-register((
  ([R01], [风险], [中], [高], [应对措施], [负责人], status-badge("关注")),
))

#deliverable-table((
  ([D01], [交付物], [负责人], [日期], [验收方法], status-badge("进行中")),
))
```

## RACI

```typst
#raci-table(
  ([活动], [发起人], [PM], [业务], [技术]),
  (
    ([需求批准], [A], [R], [R], [C]),
    ([技术设计], [I], [C], [C], [A/R]),
  ),
)
```

## 架构节点

```typst
#grid(
  columns: (1fr, 10mm, 1fr),
  align: center + horizon,
  architecture-node([控制面], [领域模块与工作流]),
  flow-arrow([mTLS]),
  architecture-node([执行集群], [Kubernetes 与硬件]),
)
```

## 清单、审批和签署

```typst
#checklist((
  (true, [需求已评审。]),
  (false, [安全测试已完成。]),
))

#approval-table()
#signature-table()
```
