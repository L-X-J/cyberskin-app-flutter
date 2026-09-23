# auth Feature

账号与会话业务域，负责登录、注册、凭证生命周期和用户身份状态。

`domain/` 定义用户模型、登录输入值和认证 Repository 抽象；`data/` 实现邮箱、Apple、
Google 登录、验证码、当前用户和登出，并只在数据层将 token/clientId 写入安全存储。
页面不得读取令牌或调用认证 API。

目录与文件：

- `data/`：认证 API 和会话凭证的远端 Repository；文件说明见 `data/README.md`。
- `domain/`：用户模型、登录请求值对象和认证 Repository 接口；文件说明见 `domain/README.md`。
- `presentation/`：登录页面和 Controller 的预留展示层，当前无 Dart 实现；见 `presentation/README.md`。
- 当前 Feature 根目录无 Dart 文件。
