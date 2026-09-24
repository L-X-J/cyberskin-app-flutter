# feedback/data 目录

实现 OSS 预签名、完成确认、原始字节 PUT 和反馈创建。

除预签名原始字节上传外，所有业务 API 都通过 GetConnect 传输边界；上传和业务请求都会
写入无敏感数据的 `NetworkRequestMonitor`，失败同样转换为 `Result`，不把 http 异常泄漏给
展示层。

预签名上传的统一 API 日志只记录清理 query 后的 scheme、host、path、请求头、状态和耗时，
不记录签名参数、附件参数或二进制载荷。未来新增下载实现时必须使用同一文件传输标记，
禁止把下载内容交给普通 API 日志路径。

文件职责：

- `feedback_remote_repository.dart`：创建反馈、申请附件预签名、上传原始字节和确认上传完成，并映射为统一 `Result`。
