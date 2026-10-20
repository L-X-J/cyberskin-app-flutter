# Free Control Presentation Widgets

## 目录职责与边界

本目录属于 `features/control/free_control/presentation`，负责提供自由控制页面的网格布局器与各通道控制卡片 Widget。
所有组件严格遵循展示层规范，仅消费 `domain` 层定义的 `FreeControlComponentConfig` / `FreeControlLayout`，不直接接触 HTTP、BLE 原始帧或底层硬件逻辑。

## 当前文件清单与职责

- `heat_toggle_control.dart`：加热 1x1 液态玻璃开关组件（对应 `heat-a.png`），提供开关状态与回调。
- `heat_bar_control.dart`：加热 1x2 横向液态玻璃开关组件（对应 `heat-b.png`），提供能力提示、开关状态与回调。
- `suck_toggle_control.dart`：吸附/吮吸 1x1 液态玻璃开关组件（对应 `suck-a.png`），使用 Group 28.svg 的 Canvas 重绘按钮并提供开关回调。
- `suck_multi_control.dart`：吸附/吮吸 2x2 多模式组件（对应 `suck-b.png`），使用 Canvas 重绘开关和波纹 logo，开启后按后台模式配置流式展示模式按钮。
- `free_control_layout_builder.dart`：动态 2 列网格布局构建器，基于 `(row, col)` 与跨行/跨列规则对齐后台 WebAdmin 画布编排。
- `free_control_component_placeholders.dart`：自由控制模块展示与降级兜底容器，负责根据组件 variant 映射对应的真实模块或占位展示。
- `stepped_capsule_control.dart`：通用分档胶囊自绘组件（Stepped Capsule Control），封装基于 Canvas 的流体底色线性渐变、反向路径高斯模糊深层漫反射光晕（30%~35% 空间深度）、手势拖拽跨档即时填充与轻触震动反馈机制。
- `telescopic_stepped_control.dart`：伸缩通道分档控制组件（深度还原 `thrust-a.png` 竖向 3x1 规范），基于 `SteppedCapsuleControl` 应用电光蓝流体渐变与对应双向箭头图标。
- `telescopic_horizontal_stepped_control.dart`：伸缩横向分档控制组件（深度还原 `thrust-b.png` 横向 1x2 规范），基于 `SteppedCapsuleControl(orientation: Axis.horizontal)` 应用电光紫罗兰流体渐变、右侧动态 `Gear X / Y` 档位文本与水平手势选档机制。
- `telescopic_horizontal_variable_control.dart`：伸缩横向无级变速控制组件（深度还原 `thrust-d.png` 横向 1x2 规范），基于 `VariableCapsuleControl(orientation: Axis.horizontal)` 应用 `img_rectangle_110_2.svg` 的粉紫至青绿色渐变和动态百分比调速。
- `telescopic_variable_control.dart`：伸缩竖向无级变速控制组件（深度还原 `thrust-c.png` 竖向 3x1 规范），基于 `VariableCapsuleControl(orientation: Axis.vertical)` 提供伸缩主题、左侧刻度、动态百分比与纵向连续调速。
- `vibration_stepped_control.dart`：震动通道分档控制组件（深度还原 `vibration-a.png` 竖向 3x1 规范），基于 `SteppedCapsuleControl` 应用电光洋红紫流体渐变与对应手机震动图标。
- `vibration_horizontal_stepped_control.dart`：震动横向分档控制组件（深度还原 `vibration-b.png` 横向 1x2 规范），基于 `SteppedCapsuleControl(orientation: Axis.horizontal)` 应用电光青靛流体渐变、右侧动态 `Gear X / Y` 档位文本与水平手势选档机制。
- `variable_capsule_control.dart`：通用连续无级变速胶囊自绘组件（Variable Capsule Control），支持横向（1x2）与纵向（3x1）两种排版布局，封装基于 Canvas 的线性流体底色（浅紫罗兰至电光紫）、SVG 滤镜级高保真多层内发光漫反射（对齐 `img_rectangle_110_3.svg` 的 13.0 blur 与 60% 白色发光）、动态百分比指示器、连续手势滑动与轻触物理触觉反馈机制。
- `vibration_horizontal_variable_control.dart`：震动横向无级变速控制卡片组件（深度还原 `vibration-d.png` 横向 1x2 规范），基于 `VariableCapsuleControl(orientation: Axis.horizontal)` 应用电光紫流体渐变、右侧动态 `Gear XX %` 百分比文本与水平手势连续调速机制。
- `vibration_variable_control.dart`：震动竖向无级变速控制卡片组件（深度还原 `vibration-c.png` 竖向 3x1 规范），基于 `VariableCapsuleControl(orientation: Axis.vertical)` 提供左侧 100%~0% 刻度指示条、右侧上方居中大号动态百分比与自绘纵向电光紫发光滑动胶囊。
