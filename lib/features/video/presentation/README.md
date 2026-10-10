# video/presentation 目录

文件职责：

- `video_page.dart`：渲染可独立路由或嵌入主页的 Official、Browser、Local 内容状态，并按 AppScaffold Dock 几何预留底部滚动空间。
- `video_controller.dart`：加载官方视频并维护标签、Browser 输入和错误状态。
- `video_binding.dart`：装配视频页 Controller 与 VideoRepository。

视频功能的展示层。

`VideoTabContent` 只负责视频标签状态展示；一级导航由外层 `AppScaffold` 所有，页面不得在
内容子树内重复绘制 Dock 或写死其底部余量。

播放器资源、文件权限和远端请求仍由数据层或平台能力负责，页面只消费统一状态；Local
选择入口暂保留为 UI 边界，未引入文件选择插件。
