# core/widgets 目录

跨业务域通用组件的目录。

只有语义、交互契约和所有权均稳定且被多个 Feature 使用的组件才应放在此处。单一
Feature 的组件留在对应 `presentation` 目录；不得为减少少量重复代码而创建通用组件。

文件职责：

- `app_image.dart`：统一资源、本地文件和网络图片的加载状态、占位展示、预加载与图片预览。
- `app_lottie_background.dart`：统一页面 Lottie 背景的铺满方式、底色、播放倍速与无限循环策略。

`AppLottieBackground` 默认加载 `init_bg`，使用 `BoxFit.cover` 和 App 统一背景色。调用方
通过 `playbackSpeed` 调整动画速度；组件内部固定无限循环、忽略指针并排除装饰语义，因此
只应作为页面背景使用，不应承载交互或业务状态。
