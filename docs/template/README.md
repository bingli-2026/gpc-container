# Typst Project Kit

一套适合中文专业项目管理文档的 Typst 模板与公共组件。目标是：**统一视觉、直接 import、填空即用、适合立项/设计/周报/会议/变更/验收全生命周期**。

## 目录

```text
template/
├── typst.toml
├── project-kit.typ              # 所有公共组件的单一入口
├── templates/
│   ├── 00-quick-start.typ
│   ├── 01-project-charter.typ
│   ├── 02-project-proposal.typ
│   ├── 03-project-plan.typ
│   ├── 04-design-report.typ
│   ├── 05-weekly-status-report.typ
│   ├── 06-meeting-minutes.typ
│   ├── 07-risk-issue-register.typ
│   ├── 08-change-request.typ
│   ├── 09-acceptance-report.typ
│   └── 10-project-retrospective.typ
├── examples/components-showcase.typ
├── COMMON-FUNCTIONS.md
├── scripts/install-local.sh
└── Makefile
```

## 用法一：项目内相对导入

复制 `project-kit.typ` 到你的项目，或保持本目录结构：

```typst
#import "../project-kit.typ": *

#show: project-document.with(
  title: "项目标题",
  subtitle: "文档副标题",
  doc-type: "PROJECT DOCUMENT",
  version: "V1.0",
  date: "2026-07-22",
  organization: "某某单位",
  owner: "项目负责人",
  toc: true,
)

= 执行摘要

#callout([管理建议], [在这里填写关键结论。], tone: "teal")
```

若需要替换封面而不是仅修改标题、版本等元数据，可传入 `cover-renderer`。该函数接收
`title`、`subtitle`、`doc-type`、`version`、`date`、`organization`、`owner` 和 `status`：

```typst
#let custom-cover(title, subtitle: none, ..meta) = [
  #align(center)[#text(size: 28pt, weight: "bold")[#title]]
]

#show: project-document.with(
  title: "项目标题",
  cover-renderer: custom-cover,
)
```

## 用法二：安装为 Typst 本地包

Linux：

```bash
./scripts/install-local.sh
```

安装后导入：

```typst
#import "@local/project-kit:0.1.0": *
```

默认安装位置：

```text
~/.local/share/typst/packages/local/project-kit/0.1.0
```

## 编译

```bash
typst compile templates/01-project-charter.typ build/project-charter.pdf
make all
```

建议使用 Typst 0.15+。中文字体默认按以下顺序回退：

1. Noto Sans CJK SC
2. SSource Han Sans CN
3. Noto Sans CJK JP
4. Noto Sans

可在 `project-kit.typ` 中修改 `default-fonts`。

## 最常用组件

```typst
#status-badge([进行中])
#priority-badge([P0])
#callout([标题], [正文], tone: "warning")
#metric-card([完成度], [72%], [本周增加 8%])
#progress-bar(percent: 72%, label: [项目完成度])
#milestone-table(rows)
#risk-register(rows)
#action-table(rows)
#decision-table(rows)
#issue-table(rows)
#raci-table(headers, rows)
#checklist(items)
#architecture-node([标题], [说明])
#signature-table()
```

## 色调参数

可用 `tone`：

- `blue`：普通信息
- `teal`：建议、架构和管理结论
- `green` / `success`：完成和通过
- `amber` / `warning`：关注和偏差
- `red` / `danger`：阻塞和重大风险
- `purple`：基础设施或支撑能力

## 设计约定

- 封面和正文由 `project-document` 统一管理。
- 长文档打开 `toc: true`，短周报、纪要和变更单使用 `cover: false`。
- 表格行使用 tuple，例如：

```typst
#action-table((
  ([A01], [完成评审], [张三], [2026-08-01], status-badge([进行中])),
))
```

- 文档正文尽量描述结果、依据和决策，不只记录活动。
- 正式发布前替换所有“待填写”“待指定”和示例数据。
