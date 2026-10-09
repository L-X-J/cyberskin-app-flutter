# 主页

## 来源与状态

- PRD：`docs/Cyberskin_PRD_v1.1.0.md` 第 5.1、5.2、10 章。
- Ardot：`https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A1`。
- 节点：`389:2`（首页-未连接设备）、`389:109`（已连接主页）。
- 最后读取：2026-10-09。
- 验收状态：静态实现，待 Flutter 基准截图与实机视觉对照。

## 基准环境

| 项目 | 值 | 说明 |
| --- | --- | --- |
| 逻辑尺寸 | 402 x 874 / 402 x 949 | Ardot 未连接/已连接画板。 |
| 平台与系统区域 | iOS 视觉参考 | 状态栏由系统绘制，页面不自绘。 |
| 字体与缩放 | Flutter 默认字体、1.0x | 项目未接入 MiSans。 |
| 数据 | 设备、训练、广告由 Repository 提供 | Widget 测试使用 fake Repository。 |

## 页面区域

- 顶部标题、问候语和右上角头像为共享头部组件。
- 未连接状态包含扫描卡和设备型号入口，底部一级导航隐藏，仅保留全局快捷 pill。
- 已连接状态包含设备主卡、Free control、Customrhythm、Training 和广告位；底部为 Device / Video。
- 页面内容正常滚动，AppScaffold 为全局 pill 和系统区域保留底部空间。

## 视觉与素材

- 设备彩色卡片不是整图资源，使用 Flutter 双层表面绘制：底层 `#D94126`，叠加 `#F9765F` 内阴影（blur 20，y=1），上层径向渐变自上而下由 `#000000` 至 `#D94126`，模糊半径 14。
- Ardot 导出的设备图、训练缩略图和广告产品图位于 `assets/images/home/`。
- 设备型号、绑定设备、训练和广告内容均来自领域 Repository；无内容时显示可操作空态或设计示例占位。

## 数据与状态

- `HomeController` 只编排 Repository 和 `SessionController`，`HomeDashboard` 冻结渲染所需列表。
- 项目约束一次最多绑定一个设备；发现多条绑定记录时报告数据错误，不猜测当前设备。
- UI 重建、窗口变化和截图不得触发 BLE 操作或重复加载；加载由 Controller 生命周期控制。

## 适配与验收

- 窄屏：卡片按可用宽度缩小，双列入口保持两列并允许文本自然换行。
- 宽屏：内容由滚动列承载，不按设计稿宽度整页缩放。
- 大字体：标题和卡片文本自然增高，底部 pill 由 AppScaffold 重新测量位置。
- 截图目标：`build/ui/home_disconnected_402x874_text1.0.png`、`build/ui/home_connected_402x949_text1.0.png`。
- 未验证项：默认字体与 MiSans 差异、内阴影与模糊的实机光学效果、真实 BLE 连接数据。
