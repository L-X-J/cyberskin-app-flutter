# feedback Feature

用户反馈、反馈图片预签名上传和上传完成确认属于本业务域。

业务 JSON 请求使用 GetConnect；对象存储预签名 URL 的原始字节 PUT 使用专用上传边界，
不得在 Widget 中直接上传文件或拼装反馈请求。

目录与文件：

- `data/`：反馈 API、预签名上传和完成确认的 Repository 实现；见 `data/README.md`。
- `domain/`：反馈和附件模型、提交值对象及 Repository 接口；下含 `entities/`、`repositories/`。
- `presentation/`：当前尚无目录和 Dart 文件；后续页面与 Controller 应放在此处。
- 当前 Feature 根目录无 Dart 文件。
