# 全局悬浮设备快捷控件

## 依据与基准

- Ardot 文件 `729272102282180`，节点 `382:178`，控件基准 `382:179`；402 × 874 逻辑像素、默认文字缩放。
- 基准外框 126 × 68；图标为该设计的 SVG 导出，正文使用项目 Material 默认字体替代设计字体。
- Ardot GLASS 效果的光学参数无法由当前接口读取。`AppDeviceControlStyle.glass` 是可校准的初始值，外层由 `flutter_liquid_glass_plus` 绘制，不宣称像素级等同 Ardot。

## 状态与动作

| 状态 | 主/副文案 | 点击 |
| --- | --- | --- |
| Running | Running / Tap to pause | 暂停现有会话 |
| Running low battery | Running / Low battery | 暂停现有会话 |
| Paused | Paused / Tap to resume；未开始时 Tap to start | 恢复会话；未开始时打开设备页 |
| Not connected | Not connected | 打开设备页 |
| Connecting | Connecting | 禁用，防止重复操作 |

连接状态优先于残留会话；低电量只使用现有 `DeviceConnectionStatus.lowBattery`，不推断电量阈值。设计示例中的运行与暂停图标动作相反，此处按 PRD 的点击语义交换使用。

## 布局与边界

- 首页、设备页、视频主页固定于内容区域右下；个人资料等显式登记的二级页可拖动，受可用内容区域约束。
- 初始化、登录、未登记页面、全屏与模态路由隐藏。显示时从右侧屏幕边缘滑入，停靠点不跟随页面转场的横向偏移；系统关闭动画时直接显示。返回首页清除拖动位置并动画归位。
- 内容区域由 `AppScaffold` 在布局及路由转场时报告；键盘、安全区与底部导航均参与边界计算，滚动内容保留底部余量。
- 状态共用同一外框尺寸；大字体按文字测量扩展，不缩放整页或文字。窗口缩小时坐标重新钳制。

## 验收记录

Widget test 生成的四态截图位于 `build/ui/device_control_<state>_402x200_text1.0.png`；这些截图验证真实 Flutter 渲染与非空像素，仍需在 iOS/Android 实机或模拟器上比对玻璃光学效果、默认字体差异及 402 × 874 完整页面定位。测试覆盖窄屏、大字体、键盘、拖动、路由与断连动作。
