# core/widgets 目录

跨业务域通用组件的目录。

只有语义、交互契约和所有权均稳定且被多个 Feature 使用，或已明确为应用级设计契约的组件才应放在此处。单一
Feature 的组件留在对应 `presentation` 目录；不得为减少少量重复代码而创建通用组件。

文件职责：

- `app_liquid_glass_button.dart`：统一胶囊液态玻璃按钮，封装 `flutter_liquid_glass_plus` 的玻璃背景和按压形变、主题双层内阴影、加载/禁用状态及键盘操作。
- `app_image.dart`：统一资源、本地文件和网络图片的加载状态、占位展示、预加载与图片预览。
- `app_lottie_background.dart`：统一页面 Lottie 背景的铺满方式、底色、播放倍速与无限循环策略。

`AppLottieBackground` 默认加载 `init_bg`，使用 `BoxFit.cover` 和 App 统一背景色。调用方
通过 `playbackSpeed` 调整动画速度；组件内部固定无限循环、忽略指针并排除装饰语义，因此
只应作为页面背景使用，不应承载交互或业务状态。

`AppLiquidGlassButton` 是应用公共按钮样式；填充和内阴影来自 `core/theme`。
`highlighted` 是粉紫填充与双层内阴影，`subtle` 是深色填充与单层紫色内阴影；
两款都是正常的可点击样式，不将深色款当作禁用状态。完整契约见
[`液态玻璃按钮`](../../../docs/ui/components/liquid-glass-button.md)。
页面可传文案、回调、加载状态和高度，不在业务页复制效果绘制。默认 `LGQuality.standard`
适用于滚动内容，采用背景滤镜和按压形变；`premium` 使用 shader 折射，仅在固定布局及
支持该 shader 的环境中显式启用。尺寸由有界父约束决定，默认填满可用宽度。
