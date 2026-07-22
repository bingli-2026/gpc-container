// Project Kit 0.1.0
// A reusable Chinese project-management document kit for Typst 0.15+.

#let colors = (
  navy: rgb("#17324D"),
  navy2: rgb("#254B6D"),
  blue: rgb("#2D6CDF"),
  teal: rgb("#087F8C"),
  green: rgb("#2F855A"),
  amber: rgb("#B7791F"),
  red: rgb("#C53030"),
  purple: rgb("#6B46C1"),
  ink: rgb("#18212B"),
  muted: rgb("#667587"),
  border: rgb("#D6DEE8"),
  panel: rgb("#F5F8FB"),
  white: rgb("#FFFFFF"),
  blue-soft: rgb("#EEF4FF"),
  teal-soft: rgb("#EAF8FA"),
  green-soft: rgb("#ECF8F1"),
  amber-soft: rgb("#FFF8E8"),
  red-soft: rgb("#FFF1F1"),
  purple-soft: rgb("#F4F0FF"),
)

#let default-fonts = (
  "Noto Sans CJK SC",
  "SSource Han Sans CN",
  "Noto Sans CJK JP",
  "Noto Sans",
)

#let _tone(name) = if name == "success" or name == "green" {
  (colors.green-soft, colors.green)
} else if name == "warning" or name == "amber" {
  (colors.amber-soft, colors.amber)
} else if name == "danger" or name == "red" {
  (colors.red-soft, colors.red)
} else if name == "teal" {
  (colors.teal-soft, colors.teal)
} else if name == "purple" {
  (colors.purple-soft, colors.purple)
} else {
  (colors.blue-soft, colors.blue)
}

#let badge(body, tone: "blue") = {
  let pair = _tone(tone)
  box(
    fill: pair.at(0),
    stroke: 0.5pt + pair.at(1),
    radius: 3pt,
    inset: (x: 6pt, y: 2.5pt),
  )[
    #text(size: 8pt, weight: "bold", fill: pair.at(1))[#body]
  ]
}

#let status-badge(status) = {
  let s = str(status)
  if s == "正常" or s == "完成" or s == "通过" or s == "绿" {
    badge(status, tone: "success")
  } else if s == "风险" or s == "延期" or s == "阻塞" or s == "红" {
    badge(status, tone: "danger")
  } else if s == "关注" or s == "进行中" or s == "待确认" or s == "黄" {
    badge(status, tone: "warning")
  } else {
    badge(status, tone: "blue")
  }
}

#let priority-badge(priority) = {
  let p = str(priority)
  if p == "P0" or p == "紧急" or p == "高" {
    badge(priority, tone: "danger")
  } else if p == "P1" or p == "中" {
    badge(priority, tone: "warning")
  } else {
    badge(priority, tone: "blue")
  }
}

#let callout(title, body, tone: "blue") = {
  let pair = _tone(tone)
  block(
    width: 100%,
    fill: pair.at(0),
    stroke: (left: 3pt + pair.at(1), rest: 0.45pt + colors.border),
    radius: 3pt,
    inset: 10pt,
    breakable: true,
  )[
    #text(weight: "bold", fill: pair.at(1))[#title]
    #v(3pt)
    #body
  ]
}

#let metric-card(label, value, detail: none, tone: "blue") = {
  let pair = _tone(tone)
  block(
    width: 100%,
    fill: colors.panel,
    stroke: 0.5pt + colors.border,
    radius: 4pt,
    inset: 9pt,
  )[
    #text(size: 8.5pt, fill: colors.muted)[#label]
    #v(2pt)
    #text(size: 17pt, weight: "bold", fill: pair.at(1))[#value]
    #if detail != none {
      v(2pt)
      text(size: 8.5pt, fill: colors.muted)[#detail]
    }
  ]
}

#let metric-grid(items, columns: (1fr, 1fr, 1fr)) = grid(
  columns: columns,
  gutter: 8pt,
  ..items,
)

#let progress-bar(percent: 50%, label: none, tone: "blue") = {
  let pair = _tone(tone)
  block(width: 100%)[
    #if label != none {
      grid(
        columns: (1fr, auto),
        text(size: 8.5pt, fill: colors.muted)[#label],
        text(size: 8.5pt, weight: "bold", fill: pair.at(1))[#repr(percent)],
      )
      v(3pt)
    }
    #block(width: 100%, height: 7pt, fill: colors.border, radius: 4pt)[
      #block(width: percent, height: 7pt, fill: pair.at(1), radius: 4pt)
    ]
  ]
}

#let data-table(headers, rows, columns: none, header-fill: colors.navy2, compact: false) = {
  let cols = if columns == none { headers.len() } else { columns }
  let body-cells = rows.map(row => row.map(cell => [#cell])).flatten()
  table(
    columns: cols,
    inset: if compact { 4pt } else { 5.5pt },
    stroke: 0.45pt + colors.border,
    align: left + top,
    table.header(
      ..headers.map(h => table.cell(fill: header-fill)[
        #text(size: 8.8pt, weight: "bold", fill: colors.white)[#h]
      ]),
    ),
    ..body-cells,
  )
}

#let info-table(rows, columns: (34mm, 1fr, 34mm, 1fr)) = {
  let cells = rows.map(row => row.map(cell => [#cell])).flatten()
  table(
    columns: columns,
    inset: 5.5pt,
    stroke: 0.45pt + colors.border,
    ..cells,
  )
}

#let document-control(
  name,
  code: "DOC-001",
  version: "V0.1",
  status: "草案",
  date: "待填写",
  owner: "待填写",
  confidentiality: "内部",
  scope: "立项与实施",
) = info-table((
  ([*文档名称*], name, [*文档编号*], code),
  ([*版本*], version, [*状态*], status),
  ([*编制日期*], date, [*责任人*], owner),
  ([*适用阶段*], scope, [*保密级别*], confidentiality),
))

#let revision-table(rows) = data-table(
  ([版本], [日期], [责任人], [修订说明]),
  rows,
  columns: (20mm, 28mm, 28mm, 1fr),
)

#let approval-table(roles: ([项目发起人], [业务负责人], [技术负责人], [安全负责人])) = {
  let rows = roles.map(role => (role, [待填写], [□通过　□有条件通过　□退回], []))
  data-table(
    ([角色], [姓名], [审批结论], [签字/日期]),
    rows,
    columns: (32mm, 38mm, 1fr, 38mm),
  )
}

#let action-table(rows) = data-table(
  ([编号], [行动项], [负责人], [截止日期], [状态]),
  rows,
  columns: (14mm, 1fr, 27mm, 28mm, 24mm),
)

#let decision-table(rows) = data-table(
  ([编号], [决策事项], [决策结果], [决策人], [日期]),
  rows,
  columns: (14mm, 1fr, 1fr, 26mm, 27mm),
)

#let issue-table(rows) = data-table(
  ([编号], [问题/阻塞], [影响], [负责人], [计划完成], [状态]),
  rows,
  columns: (13mm, 1fr, 1fr, 25mm, 26mm, 22mm),
)

#let milestone-table(rows) = data-table(
  ([里程碑], [计划日期], [责任人], [交付物/退出条件], [状态]),
  rows,
  columns: (30mm, 27mm, 27mm, 1fr, 22mm),
)

#let deliverable-table(rows) = data-table(
  ([编号], [交付物], [责任人], [计划完成], [验收方式], [状态]),
  rows,
  columns: (14mm, 1fr, 26mm, 27mm, 1fr, 22mm),
)

#let risk-register(rows) = data-table(
  ([ID], [风险], [概率], [影响], [应对措施], [责任人], [状态]),
  rows,
  columns: (12mm, 1.2fr, 17mm, 17mm, 1.4fr, 24mm, 22mm),
  compact: true,
)

#let raci-table(headers, rows) = data-table(
  headers,
  rows,
  columns: headers.len(),
  compact: true,
)

#let checklist(items, checked: "✓", unchecked: "□") = {
  for item in items {
    let done = item.at(0)
    let body = item.at(1)
    grid(
      columns: (14pt, 1fr),
      column-gutter: 4pt,
      text(weight: "bold", fill: if done { colors.green } else { colors.muted })[
        #if done { checked } else { unchecked }
      ],
      body,
    )
    v(3pt)
  }
}

#let architecture-node(title, body, tone: "blue") = {
  let pair = _tone(tone)
  block(
    width: 100%,
    fill: colors.white,
    stroke: 0.8pt + pair.at(1),
    radius: 4pt,
    inset: 8pt,
  )[
    #align(center)[#text(weight: "bold", fill: pair.at(1))[#title]]
    #v(3pt)
    #text(size: 8.5pt, fill: colors.muted)[#body]
  ]
}

#let flow-arrow(label: none) = align(center)[
  #text(size: 18pt, fill: colors.muted)[→]
  #if label != none {
    v(-2pt)
    text(size: 7.5pt, fill: colors.muted, label)
  }
]

#let phase-card(name, period, objective, deliverables, exit) = block(
  width: 100%,
  fill: colors.panel,
  stroke: 0.5pt + colors.border,
  radius: 4pt,
  inset: 9pt,
)[
  #grid(
    columns: (1fr, auto),
    text(weight: "bold", fill: colors.navy, name), badge(period, tone: "teal"),
  )
  #v(4pt)
  #text(size: 8.5pt, fill: colors.muted)[目标]
  #objective
  #v(4pt)
  #text(size: 8.5pt, fill: colors.muted)[交付物]
  #deliverables
  #v(4pt)
  #text(size: 8.5pt, fill: colors.muted)[退出条件]
  #exit
]

#let signature-table(rows: ([项目经理], [业务负责人], [项目发起人])) = {
  let table-rows = rows.map(role => (role, [], [], []))
  data-table(
    ([角色], [姓名], [签字], [日期]),
    table-rows,
    columns: (35mm, 1fr, 1fr, 35mm),
  )
}

#let section-banner(title, subtitle: none, tone: "blue") = {
  let pair = _tone(tone)
  block(
    width: 100%,
    fill: pair.at(0),
    stroke: 0.5pt + pair.at(1),
    radius: 4pt,
    inset: 10pt,
  )[
    #text(size: 14pt, weight: "bold", fill: pair.at(1))[#title]
    #if subtitle != none {
      v(2pt)
      text(size: 9pt, fill: colors.muted)[#subtitle]
    }
  ]
}

#let document-title(title, subtitle: none, meta: none) = block(width: 100%)[
  #text(size: 23pt, weight: "bold", fill: colors.navy)[#title]
  #if subtitle != none {
    v(3pt)
    text(size: 11pt, fill: colors.muted)[#subtitle]
  }
  #v(6pt)
  #line(length: 100%, stroke: 1.2pt + colors.blue)
  #if meta != none {
    v(6pt)
    text(size: 9pt, fill: colors.muted)[#meta]
  }
]

#let project-cover(
  title,
  subtitle: none,
  doc-type: "PROJECT DOCUMENT",
  version: "V0.1",
  date: "待填写",
  organization: "待填写",
  owner: "待填写",
  status: "内部评审稿",
) = block(width: 100%, height: 297mm, fill: colors.navy)[
  #place(top + right, dx: -17mm, dy: 18mm)[
    #box(stroke: 1pt + rgb("#6FA7D4"), radius: 4pt, inset: (x: 9pt, y: 5pt))[
      #text(size: 9pt, fill: colors.white, weight: "bold")[#status]
    ]
  ]
  #place(top + left, dx: 20mm, dy: 31mm)[
    #block(width: 165mm)[
      #text(size: 10pt, fill: rgb("#AFC7DA"), weight: "bold")[#doc-type]
      #v(12mm)
      #text(size: 29pt, weight: "bold", fill: colors.white)[#title]
      #if subtitle != none {
        v(8mm)
        line(length: 58mm, stroke: 2pt + rgb("#45B8C5"))
        v(8mm)
        text(size: 12.5pt, fill: rgb("#D6E4EF"))[#subtitle]
      }
    ]
  ]
  #place(bottom + left, dx: 20mm, dy: -25mm)[
    #grid(
      columns: (33mm, 1fr),
      row-gutter: 5pt,
      column-gutter: 7pt,
      text(size: 9.5pt, fill: rgb("#BFD1DF"))[文档版本],
      text(size: 9.5pt, fill: colors.white, weight: "bold")[#version],

      text(size: 9.5pt, fill: rgb("#BFD1DF"))[编制日期], text(size: 9.5pt, fill: colors.white, weight: "bold")[#date],
      text(size: 9.5pt, fill: rgb("#BFD1DF"))[编制单位],
      text(size: 9.5pt, fill: colors.white, weight: "bold")[#organization],

      text(size: 9.5pt, fill: rgb("#BFD1DF"))[项目负责人],
      text(size: 9.5pt, fill: colors.white, weight: "bold")[#owner],
    )
  ]
]

#let project-document(
  title: "项目文档",
  subtitle: none,
  doc-type: "PROJECT DOCUMENT",
  version: "V0.1",
  date: "待填写",
  organization: "待填写",
  owner: "待填写",
  status: "内部评审稿",
  confidentiality: "内部",
  cover: true,
  cover-renderer: project-cover,
  toc: false,
  toc-depth: 3,
  paper: "a4",
  body,
) = {
  set document(title: title, author: owner)
  set text(font: default-fonts, size: 10.5pt, fill: colors.ink, lang: "zh")
  set par(justify: true, leading: 0.72em)
  set heading(numbering: "1.1")
  set list(indent: 1.2em, body-indent: 0.55em)
  set enum(indent: 1.2em, body-indent: 0.55em)
  set table(inset: 5.5pt, stroke: 0.45pt + colors.border, align: left + top)
  show raw.where(block: true): it => block(
    fill: rgb("#F2F5F8"),
    stroke: 0.4pt + colors.border,
    inset: 8pt,
    radius: 3pt,
  )[#it]

  show heading.where(level: 1): it => block(above: 18pt, below: 9pt, breakable: false)[
    #text(size: 18pt, weight: "bold", fill: colors.navy)[#it]
    #v(3pt)
    #line(length: 100%, stroke: 1.2pt + colors.blue)
  ]
  show heading.where(level: 2): it => block(above: 14pt, below: 6pt, breakable: false)[
    #text(size: 14pt, weight: "bold", fill: colors.teal)[#it]
  ]
  show heading.where(level: 3): it => block(above: 10pt, below: 4pt, breakable: false)[
    #text(size: 11.5pt, weight: "bold", fill: colors.navy2)[#it]
  ]
  show strong: set text(fill: colors.navy, weight: "bold")
  show link: set text(fill: colors.blue)

  if cover {
    set page(paper: paper, margin: 0pt, header: none, footer: none)
    cover-renderer(
      title,
      subtitle: subtitle,
      doc-type: doc-type,
      version: version,
      date: date,
      organization: organization,
      owner: owner,
      status: status,
    )
    pagebreak()
  }

  set page(
    paper: paper,
    margin: (top: 22mm, bottom: 20mm, left: 20mm, right: 20mm),
    header: context {
      set text(size: 8pt, fill: colors.muted)
      grid(
        columns: (1fr, auto),
        [#title], [#doc-type · #version],
      )
      v(2pt)
      line(length: 100%, stroke: 0.4pt + colors.border)
    },
    footer: context {
      line(length: 100%, stroke: 0.4pt + colors.border)
      v(2pt)
      set text(size: 8pt, fill: colors.muted)
      grid(
        columns: (1fr, auto),
        [#confidentiality], [第 #counter(page).display() 页],
      )
    },
  )

  if toc {
    heading(level: 1, outlined: false)[目录]
    outline(title: none, depth: toc-depth, indent: auto)
    pagebreak()
  }

  body
}
