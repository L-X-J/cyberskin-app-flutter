# profile/presentation 目录

用户资料功能的展示层。

当前 `profile_page.dart` 仅为导航契约占位。后续页面和 GetxController 在此实现，展示
状态通过领域契约获取；页面不得直接读取安全存储或调用资料 API。
