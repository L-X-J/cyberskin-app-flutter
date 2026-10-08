# auth/presentation 目录

账号与会话功能的展示层。

页面只收集输入和展示认证状态，登录流程与错误处理由 Controller 编排，并通过
`auth/domain` 的接口访问数据层。Google 和 Apple 的授权令牌必须由平台插件产生，未配置
插件时只能展示明确的 unsupported 状态，不能在客户端伪造 token。

文件职责：

- `auth_submit_button.dart`：邮箱流程的提交状态适配，复用公共 `AppLiquidGlassButton`，不自行绘制按钮表面。
- `login_page.dart`：唯一登录路由的背景与前景切换壳；编排首页、邮箱地址、验证码三个步骤的动画与返回。
- `login_home_step.dart`：品牌素材、第三方登录和邮箱入口的前景。
- `email_address_step.dart`：邮箱输入和 Next 发码操作；成功后才进入验证码步骤。
- `email_verification_step.dart`：六位验证码步骤、收码邮箱、重发倒计时和 Sign in 操作。
- `verification_code_input.dart`：由一个原生编辑框驱动的 3+3 格子输入，支持数字过滤、长度限制和系统自动填充。
- `login_terms_text.dart`：首页与邮箱步骤复用的协议链接，管理点击识别器生命周期。
- `login_failure_message.dart`：最小范围订阅的内联错误信息。
- `login_back_button.dart`：步骤返回的独立玻璃按钮和可访问名称。
- `login_controller.dart`：认证调用、成功发码邮箱、六位校验、重发冷却、过期请求保护、协议读取和会话跳转。
- `login_binding.dart`：装配登录页 Controller。

步骤仅是当前路由内的前景 Widget，不创建 Scaffold、背景或嵌套路由；页面壳只切换展示。
Controller 接受 Repository 结果，发码失败保留邮箱步骤，成功固定收码邮箱并开始 60 秒冷却。
返回验证码的上一层保留邮箱并清空验证码，不撤销已发送邮件的重发冷却。
