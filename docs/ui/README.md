# Cyberskin UI 设计与响应式规范

本目录是 Cyberskin Flutter UI 工作的唯一文档入口，目标是在设计稿基准条件下高保真还原，并在窗口、文本、内容和系统 inset 变化时保持可访问、可操作。

## 查阅顺序

涉及页面、组件、主题、字体、素材、布局、响应式或视觉测试时，按以下顺序阅读：

1. [项目架构规则](../../AGENTS.md)：确认 `presentation -> domain <- data`、GetX 和动态设备配置边界。
2. [核心实现规范](ui-implementation-standard.md)：布局、状态、素材和响应式实现规则。
3. 目标页面或组件的布局约定；若尚未存在，从 [页面布局约定模板](page-spec-template.md) 新建。
4. [设计 token 记录](design-tokens.md)：确认参数来源、语义和代码落地状态。
5. [视觉验收规范](visual-acceptance.md)：完成截图、适配和交付记录。

非 UI 任务无需读取本目录的全部文档。

## 依据与冲突处理

| 信息类型 | 首选依据 | 本仓库位置 |
| --- | --- | --- |
| 业务流程、设备能力、状态和错误行为 | 最新明确需求与 PRD | [Cyberskin_PRD_v1.1.0.md](../Cyberskin_PRD_v1.1.0.md) |
| 视觉参数、素材和布局基准 | 已确认 Figma 节点与设计标注 | 下方 Figma 映射 |
| Flutter 实现方式和模块边界 | 项目架构规则、现有代码与官方适配原则 | [AGENTS.md](../../AGENTS.md)、`lib/` |
| 已落地主题 token | 代码 | [`lib/core/theme/`](../../lib/core/theme/README.md)、[`docs/design_system/README.md`](../design_system/README.md) |

设计稿和 PRD 冲突时，不得静默选择其中之一。页面布局约定中记录冲突、采用的依据、影响和待决策项。设计信息缺失时，先查找同类组件与其他状态；仍无法确定的内容必须标为推断，不能沉淀为全局 token。

## 当前 Figma 参考

文件 `Cyberskin`：<https://www.figma.com/design/7K3qlkha70NsKvdpXef8bq/Cyberskin?node-id=172-2647>，文件键 `7K3qlkha70NsKvdpXef8bq`。

| 用途 | 节点 | 读取状态 | 说明 |
| --- | --- | --- | --- |
| 已连接设备首页 | `172:2774` | 已读取，2026-09-21 | 首页视觉和底部导航/pill 的代表性参考。 |
| 纵向自由控制页 | `172:3131` | 已读取，2026-09-21 | 两列模块和纵向档位控件的代表性参考。 |
| 横向自由控制页 | `172:3201` | 已读取，2026-09-21 | 单列横向档位/无级变速控件的代表性参考。 |

这些节点不是全量设计确认，也不能代替 PRD 的动态布局与状态规则。Figma 工具可用时，先读取适用的 Figma design-to-code 指引，再获取目标节点的设计上下文和截图；参考代码必须转换为 Flutter，并遵守本仓库分层。不得提交临时 Figma 导出 URL，正式资源必须进入 `pubspec.yaml` 声明的素材流程。

## 当前事实与限制

### 已验证项目事实

- Flutter 通过 FVM 固定为 `3.47.5`；Dart SDK 约束为 `^3.13.4`。
- 当前 UI 使用 Flutter Material 3 Dark Theme、GetX 路由/状态和 [`AppTheme`](../../lib/core/theme/app_theme.dart)；完整 token 说明见 [`docs/design_system/README.md`](../design_system/README.md)。字体采用 Flutter/Material 默认字体，未注册自定义字体或正式业务素材目录。
- `DeviceCapabilities.gridColumns` 目前只表达一列或两列；PRD 规定自由控制模块、样式、排序和能力由后台配置驱动。

### 实施约定

- 页面按“基准环境精确还原 + 约束式布局适配 + 可复用视觉组件 + 实际截图验收”实施。
- 每个实质性页面拥有或更新一份布局约定，描述布局行为，不把绝对坐标当成响应式规则。
- token 先落到 `lib/core/theme/`；稳定的跨业务视觉组件放在 `lib/core/`，业务组件归对应 feature 的 `presentation`。

### 待确认或受限信息

- Figma 中标注的 MiSans、渐变、玻璃、模糊和图标属于设计参考；当前实现统一使用 Flutter/Material 默认字体，MiSans 与默认字体之间的视觉差异在基准验收中记录，不作为实现前置条件。
- 代表性画板宽度 `402` 与高度 `874`、`949`、`1018` 是初始分析线索，不是全局断点或缩放公式；每个页面需在布局约定中复核。
- 2026-09-21 尝试访问三篇 Flutter 官方文档时，本机无法解析 `docs.flutter.dev`。本规范采用与其一致的窗口约束、状态保持和大屏原则，但没有把请求伪装成已成功读取；网络恢复后应复核链接内容。

## 官方参考

公共按钮组件的样式与使用契约见 [液态玻璃按钮](components/liquid-glass-button.md)。
全局设备快捷控件的 Ardot 基准、四态和定位契约见 [悬浮设备快捷控件](components/floating-device-control.md)。

- <https://docs.flutter.dev/ui/adaptive-responsive/best-practices>
- <https://docs.flutter.dev/ui/adaptive-responsive/general>
- <https://docs.flutter.dev/ui/adaptive-responsive/large-screens>

自定义节奏的六态 Ardot 映射、布局和后台运行边界见 [节奏页面](pages/rhythm.md)。
