# feedback/data 目录

实现 OSS 预签名、完成确认、原始字节 PUT 和反馈创建。

除预签名原始字节上传外，所有业务 API 都通过 GetConnect 传输边界；上传和业务请求都会
写入无敏感数据的 `NetworkRequestMonitor`，失败同样转换为 `Result`，不把 http 异常泄漏给
展示层。
