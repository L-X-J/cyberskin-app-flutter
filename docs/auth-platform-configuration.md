# App 登录平台配置

客户端登录页面包含邮箱验证码、Google 和 Apple 入口。邮箱流程可直接通过 App API 使用；
Google/Apple 必须先完成平台和后端配置，客户端不得用伪造 token 代替授权。

## Android

- 配置正确的 application/package id、签名 SHA-1/SHA-256 和 Google OAuth Android client。
- 将 release 与 debug 使用的签名分别登记到 OAuth 控制台。

## iOS

- 使用与发布包一致的 Bundle ID，并启用 Sign in with Apple capability。
- 配置 Google iOS client ID、URL scheme、Apple Service ID、Team ID、Key ID、私钥和 redirect URL。

## Backend

- 配置 Google OAuth client ID，以及 Apple Service ID、Team ID、Key ID 和私钥环境变量。
- 生产环境关闭 mock OAuth；只有本地 smoke 测试可使用文档中约定的 mock token。
- 后端负责校验 Google `idToken` 与 Apple `identityToken`，客户端只传平台 SDK 返回的原始令牌。

发布前必须使用 release 签名、正式域名和生产 OAuth 控制台配置分别验证登录、取消授权、过期令牌和退出登录。
