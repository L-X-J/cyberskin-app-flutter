# 公共液态玻璃按钮

`lib/core/widgets/app_liquid_glass_button.dart` 是应用的公共胶囊按钮，使用
`flutter_liquid_glass_plus` 的 `LGButton.custom`。认证层的 `AuthSubmitButton`
只转发文案、加载状态和回调，其他页面可直接使用公共组件。

## 视觉变体

由设计师在本次需求中确认，默认使用 highlighted；这些是正常表面变体，不表示禁用状态。

| 变体 | 填充 | 内阴影 |
| --- | --- | --- |
| highlighted | #D173AB，20% | #FFFFFF，25%，偏移 (0, 4)，blur 4，spread 0；#C59EFF，40%，偏移 (0, 0)，blur 20，spread 10 |
| subtle | #7A576C，20% | #8230FD，40%，偏移 (0, 0)，blur 20，spread 10 |

数值归 `core/theme/app_colors.dart` 和 `app_effects.dart`，页面只选择变体。
未指定偏移默认 0；正 spread 向内扩展阴影，阴影全部裁切在胶囊内部。
设计 blur 使用 blur / 2 转换为 sigma，该映射仍需设计师最终视觉校准。

## 渲染与交互

- 默认 standard 模式适配滚动内容，使用包的背景滤镜、触摸辉光和按压形变。
- premium 使用 shader 折射，只允许在支持 shader 的固定布局中显式选择。
- 包内置的静态高光和着色设为中性，避免改变设计师指定的填充和双层内阴影。
- 默认高度 58，宽度遵循有界父约束；加载时不改变尺寸。
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
