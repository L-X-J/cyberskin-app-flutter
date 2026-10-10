# 设备主页

## 来源与状态

- PRD：`docs/Cyberskin_PRD_v1.1.0.md` 第 5.2、10 章。
- Ardot：`https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A109`。
- 节点：`389:109`（已连接设备主页）。最后读取：2026-10-10。
- 验收状态：基准静态实现，已生成 Flutter 截图；真实设备数据、字体与动画仍待人工核验。

## 基准环境

| 项目 | 值 | 说明 |
| --- | --- | --- |
| 逻辑尺寸 | 402 x 949 | Ardot 设备主页画板。 |
| 平台与系统区域 | iOS 视觉参考，顶部 50、底部 34 | 系统状态栏由宿主绘制，页面通过 `viewPadding.top` 预留首屏高度。 |
| 字体与缩放 | Flutter 默认字体、1.0x | 项目未接入 MiSans。 |
| 固定数据 | Cyberskin Air、已连接、67% | `device_home_page_test.dart` fake Repository。 |
| 截图 | `build/ui/device_home_402x949_text1.0.png` | 测试预加载本地设备/训练/广告素材后生成。 |

## 页面区域

- 顶部：标题、问候语和玻璃头像入口；随页面滚动。
- 设备主卡：后台 `Device` 的名称、状态、电量、颜色和型号 ID；说明书操作只携带展示名和型号路由参数。
- 能力卡：当前为与设计一致的入口壳，控制矩阵和节奏曲线只表达入口视觉，不伪造设备运行状态或 BLE 指令。
- 训练和广告：当前 `DeviceHomeController` 没有对应 Repository，保留与已连接画板一致的稳定展示占位，不在 presentation 层新增 IO。
- 底部：`AppScaffold` 绘制左侧 211 x 68 Device / Video 导航；根级浮动控制 pill 位于右侧，不与页面滚动树耦合。

## 布局与适配

- 内容水平边距 24；标题通过页面入口捕获的 `viewPadding.top` 计算顶部起点，避免壳层重建后的 inset 丢失。
- 主卡 179，高度能力卡 170，训练卡 136，广告卡 124；正文在 `ListView` 内滚动，底部由 `AppScaffold` 预留导航与浮动 pill 可达空间。
- 窄屏保持两列能力入口，卡内文字可自然换行；长设备名、电量和标签使用截断或允许内容压缩，不按画板缩放整页。
- 空态、错误态和刷新状态来自 `DeviceHomeController`；截图和布局变化不触发 Repository 或 BLE 操作。

## 已知限制

- 默认 Roboto 与设计 MiSans 的字宽、行高存在差异。
- 训练和广告当前是稳定视觉兜底，待有对应领域 Repository 后替换为后台内容。
- 玻璃、模糊和渐变为 Flutter 实现，仍需要真机光学效果校准。
