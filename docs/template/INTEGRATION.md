# 项目内接入说明

此目录从 `/data/Downloads/typst-project-kit` 引入，作为项目内可复现的 Typst 项目文档组件库和模板集合。

在 `docs/design/` 下的新文档中直接使用公共组件：

```typst
#import "../template/project-kit.typ": *

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
```

设计文档 `spec1.typ` 已按此方式接入。需要新建设计报告时，可复制 `templates/04-design-report.typ`，并将首行改为上面的相对导入。
