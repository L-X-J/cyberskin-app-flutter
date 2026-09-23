# core/theme 目录

应用主题和视觉参数的代码真相源。

当前 `app_theme.dart` 定义品牌种子色并构建 Material 主题。页面样式应优先引用
`ThemeData`、`ColorScheme` 和此目录提供的 token，不在 Feature 中复制数值。设计源与
落地状态说明见 `docs/ui/design-tokens.md`。

文件职责：

- `app_theme.dart`：创建应用级 `ThemeData` 和 Material 颜色方案，供 `app` 和 Feature 页面使用。
