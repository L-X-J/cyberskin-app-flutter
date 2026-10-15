# core/widgets 目录

跨业务域通用组件的目录。

只有语义、交互契约和所有权均稳定且被多个 Feature 使用，或已明确为应用级设计契约的组件才应放在此处。单一
Feature 的组件留在对应 `presentation` 目录；不得为减少少量重复代码而创建通用组件。

文件职责：

- `app_liquid_glass_button.dart`：统一胶囊液态玻璃按钮，封装 `flutter_liquid_glass_plus` 的玻璃背景和按压形变、变体内辉光、加载/禁用状态及键盘操作。
- `app_image.dart`：统一资源、本地文件和网络图片的加载状态、占位展示、预加载与图片预览。
- `app_lottie_background.dart`：统一页面 Lottie 背景的铺满方式、底色、播放倍速与无限循环策略。
- `app_img_group_80_card.dart`：使用 Canvas 绘制可配置颜色的 `img_group_80_2.svg` 背景卡片，供设备型号和模式入口复用。
- `app_layered_gradient_card.dart`：统一双层渐变卡片的底色、内阴影、径向渐变和模糊图层顺序。

`AppLottieBackground` 默认加载 `init_bg`，使用 `BoxFit.cover` 和 App 统一背景色。调用方
通过 `playbackSpeed` 调整动画速度；组件内部固定无限循环、忽略指针并排除装饰语义，因此
只应作为页面背景使用，不应承载交互或业务状态。

`AppLiquidGlassButton` 是应用公共按钮样式；填充和内阴影来自 `core/theme`。
`highlighted` 是粉紫填充与淡紫内辉光，`subtle` 是深色填充与单层紫色内阴影，
`translucent` 只使用 `#1FFFFFFF` 填充，不叠加内部上高光；
两款都是正常的可点击样式，不将深色款当作禁用状态。完整契约见
[`液态玻璃按钮`](../../../docs/ui/components/liquid-glass-button.md)。
背景色由对应主题变体的圆角表面提供；`LGButton.custom` 使用透明 tint 绘制玻璃边缘和
触摸效果，公共组件仅额外绘制设计要求的内阴影与键盘焦点环，不叠加手工描边。
默认 thickness 30、lightIntensity 0.65，保证紧凑图标按钮仍能看到包组件自身的玻璃轮廓。
需要保留品牌图片的头像或素材入口可通过 `child` 注入内容，仍由公共组件提供玻璃表面
和无障碍语义；不要回退到页面内直接调用 `LGButton.custom`。
页面可传文案、回调、加载状态和高度，不在业务页复制效果绘制。默认 `LGQuality.standard`
适用于滚动内容，采用背景滤镜和按压形变；`premium` 使用 shader 折射，仅在固定布局及
支持该 shader 的环境中显式启用。尺寸由有界父约束决定，默认填满可用宽度。
紧凑文案按钮可在无界 Row 中按文字宽度定宽，图标按钮通过 `width`、`height` 与 `borderRadius`
表达方形或胶囊几何。

`AppLayeredGradientCard` 是纯视觉表面组件，不承载业务颜色语义或点击行为。调用方显式传入
底层纯色，上层默认从黑色过渡至该底色，也可覆盖渐变颜色。默认规格归
`AppLayeredGradientStyle`，模糊使用 `AppBlur` 的统一工程映射。先绘制底色与内阴影，
再叠加独立模糊的径向渐变，最后绘制内容；完全不透明的上层会遮住底层，底层高光
只从模糊后的边缘透出。未指定高度时由内容定高，支持 ListView 的无界高度约束。
`AppLayeredGradientCard.scan` 使用扫描卡主题预设；`innerShadowSpread` 为非负内扩散量，
通过收缩阴影遮罩的透明孔洞实现，默认零以保持其他卡片效果。
