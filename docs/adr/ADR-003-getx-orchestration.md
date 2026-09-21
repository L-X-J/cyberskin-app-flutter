# ADR-003：使用 GetX 进行应用编排与原子化响应式更新

状态：Accepted

## 背景

项目会大量使用 AI 进行增量开发，需要统一路由、依赖注入、共享状态和 API 调用方式。设备控制页面包含高频状态更新，整页重建会增加性能和维护风险。

## 决策

- 路由：`GetMaterialApp`、`GetPage` 和命名路由。
- 依赖：`Bindings` 注册 Repository、Controller 和 API 客户端。
- 状态：`GetxController` + 独立 `Rx` 字段。
- API：GetX `GetConnect` 作为网络客户端；Repository 隔离业务与网络细节。
- UI：`Obx` 只包裹直接依赖变化的最小子树。

## 约束

Controller 不写 Widget 布局；Widget 不直接调用 HTTP；不得把整个 Page 放进一个大 `Obx`；新增状态先判断是否需要跨组件共享。
