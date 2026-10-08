# profile/presentation 目录

用户资料与会话管理的展示层。

当前 `profile_page.dart` 仅为导航契约占位。后续页面和 GetxController 在此实现，展示
状态通过领域契约获取；页面不得直接读取安全存储或调用资料 API。

文件职责：

- `profile_page.dart`：展示当前用户摘要和退出入口。
- `profile_controller.dart`：通过 `AuthRepository` 加载当前用户并清理会话。
- `profile_binding.dart`：装配资料页 Controller。
