# app/bindings 目录

GetX 依赖注入装配目录。

- `app_binding.dart`：注册应用生命周期内共享的 Repository、API 客户端和控制器。
- `device_binding.dart`：注册仅属于设备标签页生命周期的控制器。
- `init_binding.dart`：注册初始化页使用的启动配置控制器。

绑定只负责组装依赖，不实现业务规则。需要替换实现时，应通过构造函数或绑定层注入，
避免页面自行查找或创建底层服务。
