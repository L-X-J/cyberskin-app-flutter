# video/presentation 目录

文件职责：

- `video_page.dart`：渲染 Official、Browser、Local 三种内容来源状态和共享底部导航。
- `video_controller.dart`：加载官方视频并维护标签、Browser 输入和错误状态。
- `video_binding.dart`：装配视频页 Controller 与 VideoRepository。

视频功能的展示层。

播放器资源、文件权限和远端请求仍由数据层或平台能力负责，页面只消费统一状态；Local
选择入口暂保留为 UI 边界，未引入文件选择插件。
