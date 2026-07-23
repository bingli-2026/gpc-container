# 前端 UI 契约：响应式布局、组件与加载状态

**Status**: frozen-for-frontend-implementation
**Contract version**: 1.3
**Depends on**: [phase1.openapi.yaml](phase1.openapi.yaml)

本契约约束 Next.js 呈现层的共同实现方式，不增加控制面 API 字段，也不提供浏览器端授权。资源、权限、
错误与操作状态只来自控制面响应。

## 平台与组件边界

1. 使用 Next.js App Router、Tailwind CSS v4、shadcn/ui 与 Radix UI primitives。
2. `components/ui/` 只放 shadcn/ui 受管基础组件和主题；`components/layout/` 只拥有 shell、容器、导航
   与 `ResponsiveGrid`；领域组合组件位于 `components/features/<context>/`。
3. 业务页面不得复制 Button、Dialog、Sheet、Select、Tooltip、Table、Skeleton 或基础表单交互。新增基础
   primitive 必须先证明受管组件不足，并提供键盘和 ARIA 测试。
4. Next.js 仅通过 BFF 调用 Go API；不连 PostgreSQL、不暴露服务端秘密、不替代 Go API 授权。

## 栅格契约

所有页面使用 `PageContainer` 和 `grid grid-cols-12 gap-4 md:gap-6`。窄屏默认 `col-span-12`，通过
mobile-first `sm:`、`md:`、`lg:`、`xl:` class 调整跨栏，禁止任意像素宽度或各页自定义断点。

| 视口 | 12 栏跨栏规则 |
|---|---|
| `< sm` | 主内容和危险操作跨 12 栏；导航为 Sheet。 |
| `sm` | 概览卡可并列为 6/6。 |
| `md` | 导航/内容可为 3/9，或内容区块 6/6。 |
| `lg` | 指标可为 3/3/3/3，详情主区/操作区为 8/4。 |
| `xl` | 终端筛选/记录可为 3/9，完整表格使用主内容区。 |

宽表必须提供窄屏摘要、关键字段优先级或边界明确的滚动容器；不得依赖整页横向滚动。

## 读取与加载状态

| 读取边界 | 正常 UI | 加载 UI | 失败 / 无权 UI |
|---|---|---|---|
| 路由 shell | 页面结构、导航 | `loading.tsx` App Shell Skeleton | 错误边界只显示安全关联 ID。 |
| 班级与工作区 | 切换器、指标、卡片 | 选择器、指标卡、卡片行 Skeleton | 空态和不可枚举状态一致。 |
| 工作区详情 / 操作 | 字段组、操作条、历史 | 字段组和历史行 Skeleton | 安全错误，不输出运行时细节。 |
| 终端 / 任务 / 审计 | 筛选和表格/详情 | 筛选栏和表格行 Skeleton | 不显示用户、内容、任务或审计目标。 |

页面使用 Server Component 获取初始数据；独立读取以 `Suspense` 流式完成。Skeleton 外形必须匹配替代组件，
到达真实数据前不得显示名称、数量、状态、权限或历史缓存。Skeleton 为装饰性，加载区域使用 `aria-busy`，
并尊重 `prefers-reduced-motion`。

## 写入与可访问性

生命周期和治理命令必须显示控制面返回的 operation ID 与安全状态。pending 时保留当前数据、禁用同一命令
重复提交并继续使用原幂等键；不得通过客户端猜测成功。Dialog/Sheet 必须支持键盘开关与焦点恢复，颜色
不能成为状态唯一表达；删除必须明确数据处置选择和后果。

## 已冻结的前端读写映射

- 工作区详情使用 `Workspace.volume`；操作历史使用 `GET .../workspaces/{workspaceId}/operations`；未绑定卷的
  重绑候选和单独删除分别使用 `GET` / `DELETE .../volumes`。
- 终端页使用 `actorId`、`workspaceId`、`direction`、`from`、`to`、`cursor` 和 `pageSize` 查询参数；响应中
  的主体显示字段和内容均已按班级授权过滤。
- 培训期状态、关闭、导出和仅管理员清理均以 Operation 表达；导出成功后只通过 Operation 的受控结果
  路径下载，下载时再次授权并审计。长期任务的详情、取消、授权和撤销使用 Task/TaskGrant 读模型与
  同样的幂等 Operation 语义。
- Profile 返回批准状态、管理员可管理的领域级资源策略、数值额度和调度提示；安全/合规撤销返回 Operation，
  不可在页面中假定已清理完成。班级/平台运营摘要仅返回可展示的积压、采集和节点健康，不返回设备路径、
  资源键或运行时配置。
- `/me.capabilities` 仅用于非权威的菜单可见性优化；任何命令仍必须接受 Go API 的最终授权结果。删除
  工作区必须使用独立 `DELETE` 请求并提交必填的 `dataDisposition`，前端不得给出默认选择。

## 验收证据

1. 在 375px、768px、1024px、1440px 验证 12 栏跨栏和窄屏表格替代。
2. 延迟独立读取，验证 route/区块 Skeleton、流式完成、无布局跳动和无资源泄露。
3. 使用键盘验证导航、Dialog/Sheet、表单错误、pending 与焦点恢复；验证减少动画偏好。
4. 对同一路径验证空态、`NotDisclosed` 与成功态，确认前两者不泄露目标存在性。
