# 视频页

## 来源与状态

- PRD：`docs/Cyberskin_PRD_v1.1.0.md` 第 9 章。
- Ardot：`https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A1`。
- 节点：`389:226`（Official）、`389:274`（Browser 视觉参考）。
- 顶部来源导航：`https://ardot.tencent.com/file/729272102282180?node_id=567%3A1`，节点 `567:3`–`567:7`。
- 顶部导航最后读取：2026-10-23（402 × 847 画板）。
- 顶部导航验收：2026-10-23 已完成 Flutter widget 渲染、位置和来源切换核验；播放器联调及 iOS 真机光学效果待验收。

## 页面区域

- 顶部由 `LGButton.custom` 显示 Official / Browser / Local，选中胶囊独立滑动；按钮命中区域固定，来源状态与横向 PageView 共用 Controller。
- 基准导航位于画板 `(23, 80)`，尺寸 `356 × 52`；内部三枚 `112 × 44` 胶囊、6px 间距，上下各留 4px。文字为 16px Regular / 21px 行高，参数统一归属 `AppVideoStyle`。
- 当前壳层使用零高度 appBar，清除了 `padding.top` 但未缩短内容体；导航沿用 `statusBarHeight` 从 GetX 全局 MediaQuery 读取 `viewPadding.top` 预留系统安全区，其下留 18px；内层 SafeArea 只保护左右，不重复补偿顶部。全出血内容体沿用同一定位。
- 轨道为白色 20% 填充与背景模糊，外层 `LGContainer` 提供采样；选中胶囊使用独立玻璃层、SVG 渐变填充和内缘高光。点击与横滑切页时胶囊平移，系统减少动态效果时立即定位。
- 胶囊填充以用户提供的 `tmp/img_rectangle_32_6.svg` 为准，按 112×44 viewBox 和 userSpaceOnUse 坐标原生绘制，保留 #C477FF → #F025FA、20% 透明度，运行时不依赖 tmp 文件。SVG 不包含玻璃描边，参考 Ardot 单独绘制 0.75px 内缘渐变高光，并关闭库内照明，避免重复轮廓。保留平台默认字体；高光与折射参数属于工程映射，真机视觉仍待验收。
- Official 由 `VideoRepository` 提供封面与标题；空态、加载态和错误态独立展示。
- Browser 提供 URL 输入框；实际内置播放器由后续平台能力接入。
- Local 提供本地视频选择入口和 Privacy first 说明；本轮不引入文件选择插件。
- 底部复用 Device / Video 导航和全局设备快捷 pill。

## 数据与边界

- `VideoController` 维护标签、官方视频、Browser 输入和加载错误。
- 页面不直接发 HTTP，不持有播放器或文件句柄。
- Official 背景使用 `assets/images/video/official_background.png` 作为无封面时的视觉兜底。

## 适配与验收

- 标签保持等宽可点击区域；窄屏按可用宽度收缩，宽屏居中且宽度不超过基准宽度。大字体增加轨道高度，过长标签显示省略号并保留完整无障碍名称。
- Browser 输入框使用独立 Stateful 生命周期，响应式更新不会重置光标。
- 截图目标：`build/ui/video_official_402x847_text1.0.png`、`build/ui/video_browser_402x847_text1.0.png`、`build/ui/video_local_402x847_text1.0.png`。
- 未验证项：真实视频播放、系统文件选择、视频音频节奏联动和实机背景裁切。

## 顶部导航本次验收（2026-10-23）

- Flutter 实际渲染基准：402 × 847、text scale 1.0、顶部 inset 62px；导航实测 `(23, 80, 356, 52)`，选中胶囊实测 `(28, 84, 112, 44)`；Browser / Local 选中位置分别为 x=146 / 264。
- 已验证：点击三来源、横滑 PageView 后标签与胶囊同步、Browser 输入保留、全屏隐藏导航；320 × 568（text 1.0 / 2.0）与 847 × 402 横屏无布局异常。
- 同时核对当前零高度 AppBar 壳层与全出血内容体的顶部定位；62px / 24px / 0px 系统 inset 均只补偿一次。
- 截图：`build/ui/video_appbar_svg_reference_background_402x847_text1.0.png` 为新版生产导航组件在 Ardot 原背景上的独立玻璃核验，`build/ui/video_appbar_svg_comparison.png` 为 Ardot / 原 LGTabBar / SVG 实现的并排对照；实际页面三态截图沿用上方路径；适配截图为 `build/ui/video_local_320x568_text2.0.png` 和 `build/ui/video_local_847x402_text1.0.png`。
- 限制：widget 环境不支持 Impeller 折射，渲染器自动回退到背景模糊；iOS 真机灵动岛、系统字体和折射效果未截图确认。现有根组件测试在进入视频页之前的 `Add Device` 断言失败。
