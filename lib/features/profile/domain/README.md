# profile/domain 目录

子目录与文件：

- `entities/`：资料实体的预留目录，当前无 Dart 文件；见 `entities/README.md`。
- `repositories/`：资料访问抽象；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

用户资料功能的领域层预留目录，当前尚无实现。

后续放置不可变资料模型、校验规则和 Repository 抽象。此层不得依赖 Flutter、GetX、
网络客户端或平台存储插件。
