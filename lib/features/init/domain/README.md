# init/domain 目录

子目录与文件：

- `repositories/`：初始化专属 Repository 的预留目录，当前无 Dart 文件；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

初始化 Feature 当前不定义独立领域模型；启动配置属于 `content` 业务域，初始化流程只编排
`ContentRepository`。后续出现稳定的初始化专属规则时再在此建立模型和抽象，避免提前抽象。
