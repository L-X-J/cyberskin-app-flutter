# Cyberskin Flutter Theme 与 Design Tokens

本主题按已确认的 Cyberskin Theme Report 建立，代码是实际运行时的唯一 token 来源；这里记录语义、来源和待校准项。Figma 画板参考基准宽度为 402 logical px，但它不是全局缩放系数，也不限制 Flutter 的系统文字缩放。

## Color Tokens

颜色定义在 [`app_colors.dart`](../../lib/core/theme/app_colors.dart)，App 页面统一背景 `scaffold` 为 `#09090A`，并包括 surface/overlay、primary 紫色系、secondary 粉紫色系、辅助蓝紫与错误色、九级文字层级、白色 alpha 和描边颜色。透明组合使用 `Color.fromRGBO`；`AppColors.withAlpha(color, opacity)` 用于按需派生颜色。颜色角色是候选语义层级，页面应依据对应设计选择，不应统一套用某一个文字色或给所有控件加描边。

## Gradient Tokens

七个可直接用于 `BoxDecoration.gradient` 的渐变位于 [`app_gradients.dart`](../../lib/core/theme/app_gradients.dart)：`purplePinkEmphasis`、`brandPinkPurple`、`grayPurpleTransition`、`blueSupport`、`darkPurpleAmbient`、`redWarningAmbient`、`purpleBackgroundAmbient`。各色标来自报告。线性方向暂用左上至右下；径向中心暂用画布中心、半径 0.75；这些是工程默认几何，不是已核实的 Figma 几何。紫色背景氛围渐变的末色按报告设为 70% 不透明度。

## Typography Scale

[`app_typography.dart`](../../lib/core/theme/app_typography.dart) 提供完整 Material `TextTheme` 和计时器、模式标题、页面标题、产品名、副标题、按钮、数值、徽标与提示等额外语义变体。字号和字重以 `AppTypography` / `AppFontWeights` 为单一代码来源；Demibold 与 Semibold 独立命名，当前都映射到 w600；Heavy 映射 w900。没有指定 `fontFamily`，沿用 Flutter 平台默认字体。所有样式暂用 1.2 行高作为工程默认值，报告没有给出行高。Flutter `TextScaler` 不做限制。

## Radius

[`app_radius.dart`](../../lib/core/theme/app_radius.dart) 定义 `radiusXxs` 2、`radiusXs` 4、`radiusSm` 8、`radiusMd` 10、`radiusMdLarge` 12、`radiusLg` 14、`radiusLgLarge` 16、`radiusXl` 18、`radiusXlLarge` 20、`radiusXxl` 26、`radiusCard` 32、`radiusButton` 39、`radiusPanel` 48、`radiusPill` 100。常用 `Radius`、`BorderRadius` 与 `circular()` 构造也在同处。

## Opacity

[`app_opacities.dart`](../../lib/core/theme/app_opacities.dart) 定义 `subtle` 0.10、`light` 0.12、`weak` 0.20、`medium` 0.30、`overlay` 0.40、`half` 0.50、`strong` 0.60、`emphasis` 0.70、`glassSurface` 0.80、`highlight` 0.90。具名语义组合（如 `secondarySurface`）仍保留在颜色 token 中。

## Blur

[`app_blur.dart`](../../lib/core/theme/app_blur.dart) 分别保留 Background Blur（10、20、23）、Layer Blur（14、36–43、110）和 Background Ambient Glow（117、140、160）的 Figma 参数，并提供 `ImageFilter.blur` 工厂。Figma blur 与 Flutter sigma 未建立经截图验证的换算；当前 1:1 系数只是显式工程默认值，应在页面视觉验收时校准，不应宣称两者视觉等价。

## Shadows & Glow

[`app_effects.dart`](../../lib/core/theme/app_effects.dart) 以 `AppEffectSpec` 记录七个报告效果。Purple Glow、Subtle Inner Highlight、Soft Raised Highlight、Strong Inner Glow、Deep Purple Glow 和 Magenta Bottom Glow 都保留为 `innerShadow`；Subtle White Drop Shadow 保留为 `dropShadow`。未由报告提供的偏移、不透明度、扩展值均为 `null`。这些是设计规格数据，不是可直接传给 `BoxDecoration.boxShadow` 的绘制指令；本阶段未引入内阴影绘制依赖。

## Flutter Theme 使用方式

应用根组件在 [`lib/app/cyberskin_app.dart`](../../lib/app/cyberskin_app.dart) 通过 `AppTheme.dark()` 接入 Material 3 深色主题。主题使用显式 `ColorScheme.dark`，并配置 scaffold、app bar、card、input、按钮和图标基础样式。特殊视觉能力通过 `AppThemeExtension` 从 context 访问：

```dart
final visual = Theme.of(context).extension<AppThemeExtension>()!;
final gradient = visual.gradients.brandPinkPurple;
final glassColor = visual.glass.surfaceColor;
final filter = visual.glass.backgroundFilter;
final glowSpec = visual.effects.purpleGlow;
```

渐变、玻璃滤镜和效果规格的类型定义位于 [`app_theme_extensions.dart`](../../lib/core/theme/app_theme_extensions.dart)。主题没有设置全局字体或文字缩放策略；系统输入、弹窗和交互仍由 Material 默认行为负责。

## 需设计师进一步核实

- 本轮 Figma 截图读取接口对提供的节点 `172:2647` 返回参数错误，未能从该节点验证精确视觉几何。
- 四个 LinearGradient 的方向、色标位置，以及三个 RadialGradient 的中心和半径。
- Background Blur / Layer Blur / Ambient Glow 到 Flutter `ImageFilter.blur` sigma 的视觉映射。
- Figma 报告未明确的行高；当前 1.2 为工程默认值。
- 阴影未提供的偏移轴、强辉光精确选值，以及 Deep Purple Glow / Magenta Bottom Glow 的不透明度和扩展量。
- 默认平台字体与设计稿 MiSans 的字宽、字面和换行差异；本阶段按要求不引入 MiSans。

涉及页面时仍需按 [`docs/ui/visual-acceptance.md`](../ui/visual-acceptance.md) 以 Flutter 实际截图校准。颜色、字号和 blur 的代码值以 `lib/core/theme/` 为准。
