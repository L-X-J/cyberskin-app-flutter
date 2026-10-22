# rhythm/presentation

GetX 状态编排与节奏界面，不执行 HTTP、缓存 IO 或 BLE 帧拼接。

- `pages/`：按 home、edit、info 分离页面；每页独有组件放各自 widgets。
- `rhythm_edit_guard.dart`：拦截绕过暂停确认的编辑器直达导航。
- `rhythm_session_controller.dart`：独立执行会话的原子响应式字段、隔离的详情预览选择、启动/停止请求防重与过期保护；停止/完成保留详情供重启。
- `widgets/`：跨节奏页面复用的背景、表面、片段摘要及确认交互。
