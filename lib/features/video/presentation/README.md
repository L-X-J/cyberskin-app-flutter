# video/presentation 目录

文件职责：

- `video_page.dart`：提供视频标签页入口占位 UI，承载后续视频列表或播放器宿主。

视频功能的展示层。

当前 `video_page.dart` 提供视频标签页入口占位。后续页面、播放器宿主和 GetxController
在此实现；播放器资源、文件权限和远端请求由数据层负责，页面只消费统一状态。
