# auth Feature

账号与会话业务域，负责登录、注册、凭证生命周期和用户身份状态。

`domain/` 定义用户模型、登录输入值和认证 Repository 抽象；`data/` 实现邮箱、Apple、
Google 登录、验证码、当前用户和登出，并只在数据层将 token/clientId 写入安全存储。
页面不得读取令牌或调用认证 API。

目录与文件：

- `data/`：认证 API 和会话凭证的远端 Repository；文件说明见 `data/README.md`。
- `domain/`：用户模型、登录请求值对象和认证 Repository 接口；文件说明见 `domain/README.md`。
- `presentation/`：登录首页、邮箱登录页和 Controller；见 `presentation/README.md`。
- `assets/images/auth/`：从 Ardot 导出的登录首页按钮视觉切图，页面通过语义化点击层复用。
- 当前 Feature 根目录无 Dart 文件。
