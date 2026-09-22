# feedback Feature

用户反馈、反馈图片预签名上传和上传完成确认属于本业务域。

业务 JSON 请求使用 GetConnect；对象存储预签名 URL 的原始字节 PUT 使用专用上传边界，
不得在 Widget 中直接上传文件或拼装反馈请求。
