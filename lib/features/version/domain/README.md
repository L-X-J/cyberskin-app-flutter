# version/domain 目录

子目录与文件：

- `entities/`：版本检查领域模型；见 `entities/README.md`。
- `repositories/`：版本查询访问抽象；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

保存版本检查的不可变模型和 Repository 抽象。

没有发布版本时后端可能返回空对象；模型必须允许所有版本字段为空。
