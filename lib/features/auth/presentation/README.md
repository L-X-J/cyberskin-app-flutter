# auth/presentation 目录

账号与会话功能的展示层预留目录，当前尚无实现。

后续页面、GetxController 和登录流程组件放在此处。页面只收集输入和展示认证状态，登录
流程、凭证刷新与错误处理由 Controller 编排，并通过 `auth/domain` 的接口访问数据层。
