# core/theme 目录

应用 Material 主题和稳定设计 token 的代码真相源。页面通过 `ThemeData`、`ColorScheme`、`TextTheme`、`AppRadius` 等使用基础样式；渐变、玻璃和辉光经 `AppThemeExtension` 暴露。设计来源和待确认值见 [`docs/design_system/README.md`](../../../docs/design_system/README.md)。

文件职责：

- `app_colors.dart`：品牌、背景、文字、alpha 和描边颜色 token。
- `app_gradients.dart`：可直接用于装饰的线性与径向渐变。
- `app_typography.dart`：语义字重、Material `TextTheme` 及额外文字变体。
- `app_radius.dart`：圆角规格与 `Radius` / `BorderRadius` 构造。
- `app_opacities.dart`：可复用透明度比例。
- `app_blur.dart`：Figma 模糊数值、Flutter sigma 默认映射及滤镜工厂。
- `app_effects.dart`：内阴影/外阴影/辉光的原始效果规格。
- `app_theme_extensions.dart`：主题可访问的渐变、玻璃和效果集合。
- `app_theme.dart`：组装唯一的 Material 3 Dark Theme。
- `app_device_control_style.dart`：Ardot 设备快捷控件的组件级视觉规格、资源路径和大字体测量；不包含业务状态。
- `app_layered_gradient_style.dart`：双层渐变卡片的默认规格，以及扫描卡独立的配色、色标、图层模糊和内阴影规格。

边界：本目录只保存跨业务域稳定的视觉参数和主题映射，不保存页面布局、业务颜色条件、设备状态或效果绘制组件。内阴影数据不能直接当成外投影使用。

- `app_rhythm_style.dart`：Ardot 自定义节奏页面共享颜色、面板圆角和操作列约束。

- `app_video_style.dart`：Ardot 视频来源导航的轨道、文字、指示器和玻璃参数，以及 Official / Local 播放器的进度条样式；大字体自然增高。
