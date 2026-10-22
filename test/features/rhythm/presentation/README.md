# 节奏展示层测试

- `rhythm_home_test.dart`：列表入场、刷新、滚动保持、减少动画、Hero 往返与全宽顶部磨砂几何。新增 402×874、1024×768、320×640 text2.0 场景，检查顶部安全区、按钮下至少 16px 余量和宽屏操作列仍限宽；生成 `build/ui/rhythm/home_frost_*_text*.png`。背景保留真实 Lottie 组件但注入空动画 fixture，截图使用 Ahem，无 API/BLE 副作用，不代表真机背景/字体视觉验收。当前运行 4/6 通过；两项双倍字体用例暴露既有 `rhythm_list_tile.dart:72` 固定卡片高度导致的 45px 底部溢出，磨砂几何断言通过，但整页大字体验收未通过。

- `rhythm_segment_sheet_test.dart`：Continue 成功后左右转场中点、同步连击保护与退出表单不可交互；1199 秒/通道模式/速度保持；达到 30 段失败不转场；新增/编辑 Confirm 关闭不转场；402×874 text1.0 与 320×640 text2.0 下滚动视口延伸到弹层底部、固定玻璃操作列局部裁切、精确底部预留及 safe-area、末通道可达；减少动态效果立即更新。
- 同次测试输出 `build/ui/rhythm/segment_continue_mid_402x874_text1.0.png`、`segment_footer_402x874_text1.0.png`、`segment_footer_320x640_text2.0.png`。使用内存能力 fixture、24px 底部安全区和测试默认 Ahem 字体，未访问 API/BLE；仅为几何/行为审阅，不是 Golden 或真机字体/折射验收。运行由主任务统一执行：`.fvm/flutter_sdk/bin/flutter test --no-pub test/features/rhythm/presentation/rhythm_segment_sheet_test.dart`。

- `rhythm_channel_editor_test.dart`：Stack 箭头不压缩列表宽度、首行保留三个模式；模式反选、重新选择与单选切换，320 宽 / text1.0 与 text2.0 下首行右侧箭头定位、首行折叠、展开和收起保留选择及卡片高度动画中间帧，单行不显示箭头；保留通道开关和速度；显式清除模式及保存往返回归，无 API/BLE 副作用。本轮未生成模式列表截图，完整弹层视觉待设备验收。

- `rhythm_info_test.dart`：无设备副作用的预览、旧会话隔离、返回暂停进度、停止/完成保留详情、重启、异步过期/防连击、断连与物理设备恢复保护；英文 Start / Stop / Restart；卡组真实重叠、预览提升起点/中间帧/终点、旧卡上退、末段收拢、不同通道数量与长模式名称的自然高度、320×640 双倍文字；片段轻触次数与减少动态效果（包括在途切换）。使用 fake 端口，不验证真实 BLE 或系统触觉。
- 运行：`fvm flutter test --no-pub test/features/rhythm/presentation/rhythm_info_test.dart`。同次生成 `build/ui/rhythm/info_deck_{rest,mid,promoted}_402x874_text1.0.png` 与 `info_deck_rest_320x640_text2.0.png`。基于 Ardot 172:3608 的既有 RhythmSegmentCard 表面，fixture 为休息/三通道长模式/休息，不连接 API/BLE。截图为局部真实 Flutter 渲染，默认 Ahem 字体呈块状，非 Golden，不代表整页字体、真机流畅度或触觉验收。

- `rhythm_slider_test.dart`：透明玻璃、视觉轨道与内缩行程、0/100 静止时约 4 逻辑像素伸出及按下/释放缩放动画逐帧边界上限、原生行程与玻璃中心对齐（LTR/RTL、402/160/100 窗口）、物理右端标签、点击/拖动、非零起点步进、键盘/辅助语义、禁用及窄屏大字体回归。
- 运行：`.fvm/flutter_sdk/bin/flutter test --no-pub test/features/rhythm/presentation/rhythm_slider_test.dart`。
- 同次测试生成 `build/ui/rhythm/slider_rest_{0,50,100}_402x874_text1.0.png` 和 `slider_drag_{0,100,partial}_402x874_text1.0.png`。这些是当前工作区的真实 Flutter Widget 测试渲染，不是 Golden 基线，不纳入源码提交。
- Fixture 使用深色面板和 0/50/100 值，无 API/BLE 副作用；文字采用 Flutter 测试默认 Ahem（截图呈块状），只能核对几何和玻璃/轨道关系，不能验证设备字体或真机折射。
