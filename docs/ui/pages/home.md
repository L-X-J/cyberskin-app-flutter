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
- 训练推荐背景独立使用 `HomeTrainingBackground`，参考 `assets/images/home/training_mode_bg.svg`：深蓝底、白色内发光、中心菱形渐变及柔化胶囊光晕，不使用公共双层径向渐变卡片。装饰坐标按 SVG 的局部基准映射到卡片边界，圆角复用 `AppRadius.card`，内容高度仍由布局决定；滤镜只作用于背景，不模糊文字与按钮。视觉效果待 Flutter 截图对照。
- Ardot 导出的设备图、训练缩略图和广告产品图位于 `assets/images/home/`。
- 设备型号、绑定设备、训练和广告内容均来自领域 Repository；无内容时显示可操作空态，不展示示例训练或广告。

## 数据与状态

- `HomeController` 只编排 Repository 和 `SessionController`，`HomeDashboard` 冻结渲染所需列表。
- 项目约束一次最多绑定一个设备；发现多条绑定记录时报告数据错误，不猜测当前设备。
- UI 重建、窗口变化和截图不得触发 BLE 操作或重复加载；加载由 Controller 生命周期控制。

## 适配与验收

- 窄屏：卡片按可用宽度缩小，双列入口保持两列并允许文本自然换行。
- 宽屏：内容由滚动列承载，不按设计稿宽度整页缩放。
- 大字体：标题和卡片文本自然增高，底部 pill 由 AppScaffold 重新测量位置。
- 已连接 Dock 优先与快捷 pill 底部对齐并排；导航按剩余横向空间收窄，必要时切换为图标模式。仅在剩余宽度不足以容纳两个 48px 触控区域及外框内边距时，导航上移至 pill 上方。滚动内容由 AppScaffold 根据相同尺寸和系统底部安全区计算可达余量，背景始终延伸到视口边缘。
- 截图目标：`build/ui/home_disconnected_402x874_text1.0.png`、`build/ui/home_connected_402x949_text1.0.png`。
- 设备首页统一使用 `/home` 的连接/未连接视图；悬浮快捷控件在未连接时返回主页。说明书动作进入 [设备介绍页](device-manual.md)，不在主页层直接读取说明书 Repository。
- 公共卡片像素回归：`test/core/widgets/app_layered_gradient_card_test.dart`；运行后生成 `build/ui/layered_gradient_card_red_170x170_text1.0.png`，验证渐变方向、前景清晰度、裁切、内阴影偏移与图层覆盖。该截图不是经设计确认的 Golden 基线。
- 未验证项：默认字体与 MiSans 差异、内阴影与模糊的实机光学效果、真实 BLE 连接数据。

## 一级底部玻璃导航（本地横向适配）

- 参考首页 Figma `172:2774` 的 Device / Video 结构，以及现有悬浮设备快捷控件的玻璃表面；本次未重新获取设计节点，不宣称新增设计参数已获确认。
- `AppLGBottomBar` / `AppLGBottomBarTab` 是从 `flutter_liquid_glass_plus 0.0.7` 导航源码裁剪适配的本地版本，保留来源和 MIT 许可；仅包含等宽分段导航，不复制搜索、额外按钮和拖动指示器。
- 每个分段使用真实 Row，图标在左、标签在右；同一个 TextButton 负责触控、键盘焦点、Enter / Space 和辅助技术激活。黑色选中指示器在固定按钮区域下方横滑，选中状态由 `selectedTab` / `onSelected` 外部控制。
- 导航每次显示时从屏幕底部整体滑入最终 Dock 位置（含窄屏堆叠和系统安全区），切换标签不重播入场动画。
- 首页一级切换共用可反向的时间轴：点击 Video 后顶部栏立即保持原高向上飞出，随后 Video 从右侧进入、Device 向左退出；返回时 Device 从左侧进入，内容就位后顶部栏从顶部飞入，避免覆盖视频。两个内容子树保持挂载，隐藏页不接收点击、焦点或语义操作，退出后暂停 ticker。
- 系统减少动态效果时直接呈现最终导航、指示器、页面和顶部栏状态。
- 外框基准为 211 × 68，宽度继续由 `widthFor` 计算，并受父级局部宽度约束；实际宽度小于 176 或 16px 文案缩放后大于 20 时仅显示图标，仍保留完整 Device / Video 语义名称，不压缩文字。
- 与悬浮控件共用 `AppDeviceControlStyle.glass`、`surface`，通过 LGContainer 的独立玻璃层与 `LGQuality.standard` 渲染；没有溢出图标、零字号标签或交互覆盖层。
- 组件 Widget 验证入口：`test/app/app_primary_tab_navigation_test.dart`。真实 Flutter 渲染产物：`build/ui/primary_navigation_device_402x200_text1.0.png`、`primary_navigation_video_402x200_text1.0.png`、`primary_navigation_viewport_220x200_text1.0.png`、`primary_navigation_viewport_320x200_text3.0.png`、`primary_navigation_constrained_402x200_text1.0.png`（局部宽度 140）、`primary_navigation_viewport_1024x200_text1.0.png`；均相对于 `build/ui/`。测试背景为固定蓝紫渐变，字体为 SDK Roboto，组件截图不等于整页或真机截图，也未建立已获设计确认的 Golden。
- 本次验证范围：横向几何、外部选择更新、两个按钮点击、键盘操作、选中语义、窄屏/局部窄约束、大字体和宽屏。未验证：首页完整组合截图、iOS/Android GPU 玻璃光学效果、读屏实机体验、MiSans 差异及设计叠图验收。既有应用测试在显示导航前的 Add Device 初始断言失败，独立记录，不据此宣称整页流程通过。
- 2026-10-23 动画验证：相关 Widget 测试覆盖导航入场（220/402 宽度）、选中块中间帧、顶部栏先退场且高度保持、左右页面入场、快速反向、低高度下滚动位置保留及减少动态效果。整页 Flutter 截图位于 `build/ui/home_tabs_{device,header_exiting,to_video,video,to_device}_402x949_text1.0.png`；选中块中间帧为 `build/ui/primary_navigation_sliding_402x200_text1.0.png`。使用 fake 设备 Repository、空视频列表、Roboto 和 50/34 安全区；本轮以用户指定动效为依据，未重取设计节点，未进行真机帧率或 GPU 玻璃效果验收。

- 2026-10-23 Android Dock 定位修正：Flutter Widget 渲染验证 320/360/393/402px 宽度、0/24px 底部安全区下导航与快捷 pill 底部对齐且保留间隔，并验证大字体空间不足时堆叠。截图位于 `build/ui/android_docks_{320,360,393,402}x800_text1.0.png`，对照图为 `build/ui/android_docks_comparison.png`；使用 fake 会话、Roboto 和默认文字缩放，未连接 Android 真机，平台玻璃效果待实机验收。

## 自由控制入口转场

- 点击 Free control 卡片或箭头后，卡片表面绕 Y 轴翻转并淡出，标题通过 Hero 从两行移动并排成控制页的单行标题；返回时沿相同路径还原。
- 自由控制路由使用 560ms 淡入，避免默认侧滑干扰共享标题轨迹。标题与旋转表面分离，保证 Hero 的测量边界始终轴对齐。
- 系统减少动态效果时跳过标题飞行、卡片翻转及页面淡入。静态卡片样式和布局保持原约定。

## 聚合内容接入（2026-10-22）

训练和广告改为 `/app/v1/home` 一次聚合，型号过滤、真实摘要、轮播生命周期和跳转契约见 [Training 页面](training.md)。训练只展示首条，More 进入完整目录。刷新失败保留真实旧内容。
