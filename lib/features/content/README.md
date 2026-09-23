# content Feature

启动配置、法律/CMS 页面和广告位组成后台内容业务域。

该 Feature 只读取后台配置与内容，不承担视频播放、版本升级或用户反馈提交；这些能力由各自
Feature 管理，避免把首页相关接口聚合成无边界的 Repository。

目录与文件：

- `data/`：配置缓存、远端内容 Repository 和响应映射；见 `data/README.md`。
- `domain/`：内容模型和 `ContentRepository` 抽象；下含 `entities/`、`repositories/`；见各目录 README。
- 当前 Feature 根目录无 Dart 文件。
