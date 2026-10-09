# 视频页

## 来源与状态

- PRD：`docs/Cyberskin_PRD_v1.1.0.md` 第 9 章。
- Ardot：`https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A1`。
- 节点：`389:226`（Official）、`389:274`（Browser 视觉参考）。
- 最后读取：2026-10-09。
- 验收状态：静态实现，待 Flutter 基准截图与播放器联调。

## 页面区域

- 顶部使用 Official / Browser / Local 胶囊标签。
- Official 由 `VideoRepository` 提供封面与标题；空态、加载态和错误态独立展示。
- Browser 提供 URL 输入框；实际内置播放器由后续平台能力接入。
- Local 提供本地视频选择入口和 Privacy first 说明；本轮不引入文件选择插件。
- 底部复用 Device / Video 导航和全局设备快捷 pill。

## 数据与边界

- `VideoController` 维护标签、官方视频、Browser 输入和加载错误。
- 页面不直接发 HTTP，不持有播放器或文件句柄。
- Official 背景使用 `assets/images/video/official_background.png` 作为无封面时的视觉兜底。

## 适配与验收

- 标签保持可点击触控区域，窗口变窄时不横向溢出。
- Browser 输入框使用独立 Stateful 生命周期，响应式更新不会重置光标。
- 截图目标：`build/ui/video_official_402x847_text1.0.png`、`build/ui/video_browser_402x847_text1.0.png`、`build/ui/video_local_402x847_text1.0.png`。
- 未验证项：真实视频播放、系统文件选择、视频音频节奏联动和实机背景裁切。
