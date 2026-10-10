# 设备介绍页

## 来源与状态

- PRD：`docs/Cyberskin_PRD_v1.1.0.md` 第 5.2、10 章。
- Ardot：`https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A59`。
- 节点：`389:59`（设备介绍）。最后读取：2026-10-10。
- 验收状态：基准静态实现，已生成 Flutter 截图；后台内容媒体字段和真机字体仍待确认。

## 基准环境

| 项目 | 值 | 说明 |
| --- | --- | --- |
| 逻辑尺寸 | 402 x 1042 | Ardot 设备介绍画板。 |
| 平台与系统区域 | iOS 视觉参考，顶部 50、底部 34 | 页面无 AppBar，入口在壳层外捕获 `viewPadding.top` 后传入内容。 |
| 字体与缩放 | Flutter 默认字体、1.0x | 项目未接入 MiSans。 |
| 固定数据 | Cyberskin Air、Overview/Care/Wash | Widget test fake `DeviceCatalogRepository`。 |
| 截图 | `build/ui/device_manual_402x1042_text1.0.png` | 已预加载产品及运营素材。 |

## 页面区域

- 返回：44 x 44 的透明玻璃圆形操作，使用命名路由的系统返回语义。
- 产品视觉：居中设备、下方细线椭圆和三张媒体入口卡；入口数量遵循后台手册条目，最多在首屏展示前三项。
- 标签：按后台条目顺序显示，选中态使用底部细线；不使用 Material `ChoiceChip` 破坏设计层级。
- 正文：从 HTML 提取可读文本；优先读取 HTML 标题，缺失时使用 tab 标签。不存在正文时显示明确空态。
- 运营位：当前没有说明书广告领域数据，使用本地素材作为视觉兜底。

## 数据、边界与适配

- `DeviceManualController` 仅通过 `DeviceCatalogRepository.getManual` 读取条目、加载状态、失败和选中下标。
- 型号 ID 只来自路由 path；`DeviceManualRouteArguments.productName` 仅保留来源页面已知名称，不能替代领域模型或用作数据请求条件。
- 窄屏下三个媒体入口等分可用宽度，标题使用省略；正文和广告通过 `ListView` 向下滚动。长 HTML 不截断、不缩小正文。
- 加载、失败和无条目状态不发起重复请求；窗口重排和截图不触发 BLE 或额外网络调用。

## 已知限制

- 手册领域模型当前没有 hero/媒体字段，三张入口卡使用本地透明产品素材兜底。
- 默认 Roboto 与设计 MiSans 的字宽、行高存在差异。
- 后台 HTML 采用保守的可读文本 fallback，富文本排版和外部内容 URL 需要在内容协议明确后再扩展。
