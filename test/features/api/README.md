# features/api 测试目录

`repository_contract_test.dart` 默认运行，使用录制传输验证全部 Repository 与 OpenAPI
操作注册表一一对应。

`repository_live_api_test.dart` 是显式启用的真实服务测试，不会进入默认 CI 网络依赖。
本地联调时设置 `CYBERSKIN_LIVE_API_BASE_URL=http://192.168.1.11:8090` 后运行；测试会使用
开发环境的 `mock-apple-ok` / `mock-google-ok` 和固定邮箱验证码 `123456`，并清理创建的
节奏与设备绑定。
