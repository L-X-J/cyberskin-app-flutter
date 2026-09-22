# auth Feature

账号与会话业务域，负责登录、注册、凭证生命周期和用户身份状态。

`domain/` 定义用户模型、登录输入值和认证 Repository 抽象；`data/` 实现邮箱、Apple、
Google 登录、验证码、当前用户和登出，并只在数据层将 token/clientId 写入安全存储。
页面不得读取令牌或调用认证 API。
