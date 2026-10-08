# home 主页模块

主页是匿名可浏览的 App 一级入口，展示设备连接状态和后续业务入口。

## 边界

- `presentation` 只读取 `SessionController` 的设备状态，并把登录、设备详情事件交给路由。
- 本次仅建立 `DeviceConnectionStatus` 的可替换占位状态，真实 BLE 扫描、连接和控制由设备域后续接入。
- 设备连接和设备详情路由受统一认证 Middleware 保护；未连接的匿名用户仍可浏览主页。
