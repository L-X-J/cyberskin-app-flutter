# 设备型号详情与产品说明书页

## 来源与状态

- Ardot：<https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A59>
- 入口：未连接页的设备型号卡片，也可从设备页的说明书入口进入。
- 路由：`/device/detail/:modelId` 与 `/device/manual/:modelId` 共用 `DeviceDetailPage`。
- 动画：入口设备图和详情头图使用同一 `Hero` tag；路由使用淡入、轻微上移，型号切换使用图片淡入切换。

## 布局与交互

- `SliverAppBar(pinned: true)` 固定返回按钮；页面向上滚动后，产品名称进入 AppBar 标题。
- 顶部展示当前型号大图；型号列表横向滚动，按三项可见宽度布局，点击后重新加载该型号详情和说明书。
- 底部固定 `Introduction`、`Connection`、`Wash` 三个说明书段落入口，内容使用接口返回的 HTML 富文本结构渲染。
- 页面底部展示广告图；优先使用在线广告接口返回的第一张图片，没有数据时使用本地兜底图。

## 数据边界

- 型号列表：已有 `GET /app/v1/device-models`。
- 型号详情：已有 `GET /app/v1/device-models/{id}`，由 `DeviceCatalogRepository` 读取。
- 说明书：已有 `GET /app/v1/device-models/{id}/manual`，接口文档明确返回 `intro / connection / cleaning` 三类 HTML。
- 富文本优先使用 `contentHtml`。接口只返回 `contentUrl` 且没有 `contentHtml` 时，当前客户端不会直接把远程 HTML 当作可信 UI 执行，需要后端继续按契约回填 HTML，或后续增加受控 HTML 数据源。
- 广告：已有 `ContentRepository.listAdvertisements()` 和通用广告接口，但广告没有 `deviceModelId` 或详情页 placement 字段，无法保证按型号投放。当前页面使用全局第一张广告作为兜底。

## 后端建议

推荐在 `GET /app/v1/device-models/{id}` 的详情响应增加型号关联广告字段，例如：

```json
{
  "advertisements": [
    {
      "id": 1,
      "imageUrl": "https://...",
      "jumpType": "url",
      "jumpTarget": "https://...",
      "sort": 1
    }
  ]
}
```

这样页面只需读取一次型号详情即可完成型号、图片和广告聚合；若广告需要独立运营，也可以新增 `/app/v1/device-models/{id}/advertisements`，但不建议让页面自行组合无型号关联的全局广告。
