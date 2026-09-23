# feedback/domain/repositories 目录

文件职责：

- `feedback_repository.dart`：定义反馈创建、附件预签名申请、原始上传和完成确认的领域接口。

定义反馈 JSON API、原始附件上传和反馈创建的统一访问契约。

页面只能通过此 Repository 提交反馈，不能直接访问预签名 URL。
