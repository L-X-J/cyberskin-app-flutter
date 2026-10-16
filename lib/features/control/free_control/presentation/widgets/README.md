# Free Control Presentation Widgets

## 目录职责与边界

本目录属于 `features/control/free_control/presentation`，负责提供自由控制页面的网格布局器与各通道控制卡片 Widget。
所有组件严格遵循展示层规范，仅消费 `domain` 层定义的 `FreeControlComponentConfig` / `FreeControlLayout`，不直接接触 HTTP、BLE 原始帧或底层硬件逻辑。

## 当前文件清单与职责

- `free_control_layout_builder.dart`：动态 2 列网格布局构建器，基于 `(row, col)` 与跨行/跨列规则对齐后台 WebAdmin 画布编排。
- `free_control_component_placeholders.dart`：自由控制模块展示与降级兜底容器，负责根据组件 variant 映射对应的真实模块或占位展示。
- `stepped_capsule_control.dart`：通用分档胶囊自绘组件（Stepped Capsule Control），封装基于 Canvas 的流体底色线性渐变、反向路径高斯模糊深层漫反射光晕（30%~35% 空间深度）、手势拖拽跨档即时填充与轻触震动反馈机制。
- `telescopic_stepped_control.dart`：伸缩通道分档控制组件（深度还原 `thrust-a.png` 竖向 3x1 规范），基于 `SteppedCapsuleControl` 应用电光蓝流体渐变与对应双向箭头图标。
- `telescopic_horizontal_stepped_control.dart`：伸缩横向分档控制组件（深度还原 `thrust-b.png` 横向 1x2 规范），基于 `SteppedCapsuleControl(orientation: Axis.horizontal)` 应用电光紫罗兰流体渐变、右侧动态 `Gear X / Y` 档位文本与水平手势选档机制。
- `vibration_stepped_control.dart`：震动通道分档控制组件（深度还原 `vibration-a.png` 竖向 3x1 规范），基于 `SteppedCapsuleControl` 应用电光洋红紫流体渐变与对应手机震动图标。
- `vibration_horizontal_stepped_control.dart`：震动横向分档控制组件（深度还原 `vibration-b.png` 横向 1x2 规范），基于 `SteppedCapsuleControl(orientation: Axis.horizontal)` 应用电光青靛流体渐变、右侧动态 `Gear X / Y` 档位文本与水平手势选档机制。
