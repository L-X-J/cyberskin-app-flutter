# 设备说明书页

## 来源与状态

- Ardot：<https://ardot.tencent.com/file/729272102282180?web_only=1&node_id=389%3A59>
- 入口：未连接页的设备型号卡片，也可从设备页的说明书入口进入。
- 路由：`/device/manual/:modelId`，使用 `DeviceManualPage`。
- 动画：入口设备图和说明书头图使用同一 `Hero` tag；路由使用淡入、轻微上移，型号切换使用图片淡入切换。
- 视觉实现：型号选择卡复用 `device_model_card.dart`，与首页 `_ModelCard` 使用同一套 `AppLayeredGradientCard + LiquidGlassLayer`；产品底座使用 Ardot `389:60` 导出的原始 SVG。

## 布局与交互

- pinned sliver header 固定返回按钮；展开时显示产品标题，滚动收起后以紧凑标题替代。
- 顶部展示当前型号大图和椭圆底座；型号列表横向滚动，按三项可见宽度布局，卡片顶部间隔为 44px，点击后重新加载该型号详情和说明书。
- 底部固定 `Introduction`、`Connection`、`Wash` 三个说明书段落入口，内容使用接口返回的 HTML 富文本结构渲染。
- 页面底部仅展示在线广告接口返回的第一张有效图片；没有广告数据时不渲染广告区域，也不保留本地默认图。

## 数据边界

- 型号列表：已有 `GET /app/v1/device-models`。
- 型号详情：已有 `GET /app/v1/device-models/{id}`，由 `DeviceCatalogRepository` 读取。
- 说明书：已有 `GET /app/v1/device-models/{id}/manual`，接口文档明确返回 `intro / connection / cleaning` 三类 HTML。
- 富文本以 `contentUrl` 为真实内容源：Repository 请求 URL 返回的原始 HTML，并写入领域模型的 `contentHtml` 供页面渲染；若 URL 无效或请求失败，才回退接口已有的 `contentHtml`。页面不直接发起 HTML 请求。
- 广告：型号详情响应包含 `advertisements`。页面只展示当前型号返回的第一张有效 `imageUrl`；接口列表为空或图片地址缺失时完全隐藏广告位。

## 后端建议

`GET /app/v1/device-models/{id}` 的详情响应应返回型号关联广告字段，例如：

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

当前客户端已从该详情响应读取广告；如果后端字段结构变化，应同步更新 `DeviceModelAdvertisement` 映射和 App OpenAPI 快照。
