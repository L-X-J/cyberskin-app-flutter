# feedback/domain 目录

子目录与文件：

- `entities/`：反馈和附件领域模型；见 `entities/README.md`。
- `repositories/`：反馈访问契约；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

本目录保存反馈附件、预签名凭据、反馈提交值对象和 FeedbackRepository 抽象。

上传 URL 仅是短时能力凭据，不应被持久化或展示层缓存。
