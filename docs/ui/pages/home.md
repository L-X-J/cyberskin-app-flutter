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

- 扫描卡使用 `AppLayeredGradientCard.scan` 与 `AppScanCardStyle`：底层纯色、白色半透明内阴影（含内扩散），上层使用独立径向色标及图层模糊。参数以最新设计师答复为依据，代码 token 为唯一数值来源；28% 是径向色标，不是中心位置。暗区中心按 `build/ui/img_group_58@3x.png` 校准到卡片宽度中点、约 58% 高度，径向半径按短边归一化为 `0.6` 以收紧黑色边缘。渲染产物为 `build/ui/scan_card_surface_354x190_text1.0.png`，尚未作为设计确认的 Golden。
- 扫描卡和主页内的紧凑文字/图标操作统一复用 `AppLiquidGlassButton.translucent`：填充为 `#1FFFFFFF`，不叠加内部上高光；扫描操作为 40px 高、12px 圆角，Stop 宽度为 104px。

- 设备彩色卡片不是整图资源，使用 Flutter 双层表面绘制：底层 `#D94126`，叠加 `#F9765F` 内阴影（blur 20，y=1），上层径向渐变自上而下由 `#000000` 至 `#D94126`，模糊半径 14。
- 公共表面由 `AppLayeredGradientCard` 绘制，参数归 `AppLayeredGradientStyle`；型号卡消费后台 `cardColor`，默认上层终点跟随底色。径向中心为顶部中央，范围按短边归一化，使方形卡底部接近渐变终点，参考 `build/ui/img.png` 的明暗分布；设计未提供椭圆尺寸，精确光学效果仍需人工对照。图层 blur 使用 `AppBlur` 的统一工程映射，不宣称与设计工具的光学效果完全一致。
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
- 已连接 Dock 在常规宽度下与快捷 pill 并排；宽度/字号造成水平冲突时导航上移至 pill 上方。滚动内容由 AppScaffold 根据相同尺寸和系统底部安全区计算可达余量，背景始终延伸到视口边缘。
- 截图目标：`build/ui/home_disconnected_402x874_text1.0.png`、`build/ui/home_connected_402x949_text1.0.png`。
- 已连接设备独立路由的同构视觉入口见 [设备主页](device.md)；其说明书动作进入 [设备介绍页](device-manual.md)，不在主页层直接读取说明书 Repository。
- 公共卡片像素回归：`test/core/widgets/app_layered_gradient_card_test.dart`；运行后生成 `build/ui/layered_gradient_card_red_170x170_text1.0.png`，验证渐变方向、前景清晰度、裁切、内阴影偏移与图层覆盖。该截图不是经设计确认的 Golden 基线。
- 未验证项：默认字体与 MiSans 差异、内阴影与模糊的实机光学效果、真实 BLE 连接数据。

## 自由控制入口转场

- 点击 Free control 卡片或箭头后，卡片表面绕 Y 轴翻转并淡出，标题通过 Hero 从两行移动并排成控制页的单行标题；返回时沿相同路径还原。
- 自由控制路由使用 560ms 淡入，避免默认侧滑干扰共享标题轨迹。标题与旋转表面分离，保证 Hero 的测量边界始终轴对齐。
- 系统减少动态效果时跳过标题飞行、卡片翻转及页面淡入。静态卡片样式和布局保持原约定。
