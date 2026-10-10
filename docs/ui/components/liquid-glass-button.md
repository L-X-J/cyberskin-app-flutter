# 公共液态玻璃按钮

`lib/core/widgets/app_liquid_glass_button.dart` 是应用的公共胶囊按钮，使用
`flutter_liquid_glass_plus` 的 `LGButton.custom`。认证层的 `AuthSubmitButton`
只转发文案、加载状态和回调，其他页面可直接使用公共组件。

## 视觉变体

由设计师在本次需求中确认，默认使用 highlighted；这些是正常表面变体，不表示禁用状态。

| 变体 | 填充 | 内阴影 |
| --- | --- | --- |
| highlighted | #D173AB，20% | #C59EFF，40%，偏移 (0, 0)，blur 20，spread 10；不绘制上缘白色内高光 |
| subtle | #7A576C，20% | #8230FD，40%，偏移 (0, 0)，blur 20，spread 10 |
| translucent | #1FFFFFFF | 无额外内阴影 |

数值归 `core/theme/app_colors.dart` 和 `app_effects.dart`，页面只选择变体。
未指定偏移默认 0；正 spread 向内扩展阴影，阴影全部裁切在胶囊内部。
设计 blur 使用 blur / 2 转换为 sigma，该映射仍需设计师最终视觉校准。

## 渲染与交互

- 默认 standard 模式适配滚动内容，使用包的背景滤镜、触摸辉光和按压形变。
- premium 使用 shader 折射，只允许在支持 shader 的固定布局中显式选择。
- 圆角 tint 底色先由按钮表面容器绘制，`LGButton` 使用透明 tint 专门提供包内 fake-glass
  的边缘高光/轮廓。包内低亮度 tint 使用 multiply，直接把粉紫/深色 tint 交给它会在黑底上变黑。
- 公共默认玻璃参数使用 thickness 30、lightIntensity 0.65；这是为了让 20px 级紧凑按钮仍保留可见的包内轮廓，不是手工描边。
- 公共组件不手工描边，避免与 `LGButton` 自带玻璃轮廓错位或双重叠色。
- 主题内阴影仍由公共组件独立绘制；translucent 变体不绘制内阴影，只保留包组件的玻璃表面与边缘效果。
- 默认高度 58，宽度遵循有界父约束；显式加载状态可收拢为高度宽度相等的进度胶囊。
- 紧凑操作可显式设置宽高与圆角；无固定宽度的文字按钮在 `Row` 中按文字和水平内边距定宽。
- 需要保留头像或产品素材的图标入口可通过 `child` 注入自定义内容，仍必须提供语义 `label`；
  `child` 与 `icon`、`leadingIcon` 互斥。
- 加载或回调为空时禁用触控和键盘提交；正常状态支持 Enter/Space，键盘焦点显示轮廓。
- 不自动替换现有页面按钮，核对对应设计稿后再接入相应变体。

## 使用

```dart
AppLiquidGlassButton(
  label: 'Continue',
  variant: AppLiquidGlassButtonVariant.subtle,
  onPressed: controller.continueFlow,
)
```

验证入口：`test/core/widgets/app_liquid_glass_button_test.dart`、
`test/features/auth/presentation/auth_submit_button_test.dart`。

两款组件截图输出在 `build/ui/auth_submit_button_353x58.png` 和
`build/ui/liquid_glass_button_subtle_353x58.png`，使用黑色背景验证透射、边缘阴影和文字；
组件渲染与交互验证不替代实际页面背景上的设计验收。
