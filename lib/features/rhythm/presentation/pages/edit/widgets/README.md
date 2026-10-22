# rhythm/presentation/pages/edit/widgets

片段弹层和能力驱动通道编辑组件，所有修改仅作用于草稿。

- `rhythm_duration_wheel.dart`：局部循环时长滚轮与展示预设；固定 SVG 选择窗、吸附、邻项点击、外部秒数同步及键盘/辅助功能增减，不包含领域边界规则。
- `rhythm_duration_dialog.dart`：自定义整数秒输入，复用领域时长边界并展示校验错误。
- `rhythm_channel_editor.dart`：片段弹层通道编辑组件；模式支持反选、默认首行和 Stack 独立叠放的右侧箭头展开/收起，列表保持完整宽度，按实际宽度与文字缩放测量；卡片高度变化平滑过渡并尊重减少动态效果；仅回传草稿，不直接控制设备。
- `rhythm_slider.dart`：原生可访问滑杆与透明玻璃胶囊；两端允许约 4 逻辑像素伸出，缩放动画同步内缩行程并限制伸出上限；轨道右端可叠放标签。
- `rhythm_segment_sheet.dart`：添加/修改片段弹层：Continue 保留配置追加，Confirm 保存后关闭。
