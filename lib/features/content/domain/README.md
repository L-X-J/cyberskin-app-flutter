# content/domain 目录

子目录与文件：

- `entities/`：应用配置、CMS 页面和广告位实体；见 `entities/README.md`。
- `repositories/`：内容访问抽象；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

本目录保存启动配置、功能开关、CMS 页面、广告位模型和 ContentRepository 抽象。

功能开关缺失时在模型映射层按 false 处理，页面不应自行推断服务端开关状态。
