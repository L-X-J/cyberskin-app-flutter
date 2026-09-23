# profile/presentation 目录

用户资料功能的展示层。

当前 `profile_page.dart` 仅为导航契约占位。后续页面和 GetxController 在此实现，展示
状态通过领域契约获取；页面不得直接读取安全存储或调用资料 API。

文件职责：

- `profile_page.dart`：提供用户资料导航入口占位页，当前只展示待接入提示和返回导航。
