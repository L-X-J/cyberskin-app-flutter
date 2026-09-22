# Architecture Decisions

## ADR-001: Use feature-first GetX with explicit data boundaries

Status: Accepted

Context: PRD 同时包含账号、BLE 设备、动态能力配置、节奏、训练和视频等变化原因不同的业务域；AI 编程需要稳定、可检查的文件边界。

Decision: 使用 `app / core / features` 顶层结构，Feature 内使用 `presentation / domain / data`；GetxController 通过 Repository 接口消费数据，具体实现由 `app` 组装。

Reason: 保持领域规则与 Flutter/插件解耦，使新增设备 Adapter 或后端数据源不会污染页面代码，并且便于按业务域并行开发和测试。

Alternatives: 采用单一 `screens/` + `services/` 目录；采用全局状态单例；采用仅 UI 层的快速原型结构。

Reconsider when: 业务规模明显缩小为单页面，或团队统一迁移到另一种已批准的状态/路由架构。

## ADR-002: Separate common business protocol from device BLE protocol

Status: Accepted

Context: 通用业务协议定义 `t/v/s/h` 语义，设备 BLE 协议定义具体命令字节和特征值；未来需要支持多种设备型号。

Decision: 通用协议值对象和 BLE 帧编解码放在 `core/protocol`；每种硬件在对应 feature 的 `data` 层实现独立 Adapter。

Reason: 新设备只需新增映射，不改变上游语义解析；协议边界可以单独做单元测试。

Alternatives: 在页面直接拼 BLE 十六进制指令；为所有设备建立一个带大量分支的万能协议类。

Reconsider when: 后台或固件统一为唯一且不可扩展的协议，并确认不再支持多设备适配。

## ADR-003: Use GetX for app orchestration and atomic reactive updates

Status: Accepted

Context: 项目需要大量 AI 增量开发，路由、依赖注入、共享状态和 API 编排必须有单一约定；设备控制页还需要高频更新，不能因为一个通道变化而重建整页。

Decision: 使用 GetX `GetMaterialApp` / `GetPage` 管理路由，使用 `Bindings` 管理依赖，使用 `GetxController` + 独立 `Rx` 字段管理共享状态，使用 GetX `GetConnect` 作为 API 客户端入口。Repository 仍是业务数据访问边界。`Obx` 只包裹直接依赖变化的最小 Widget。

Reason: 统一应用编排方式，减少 AI 生成代码时出现多套状态管理和路由写法；独立 Rx 状态让高频设备状态更新保持局部重建。

Alternatives: Provider + ChangeNotifier；Bloc；在页面内直接使用全局可变单例。

Reconsider when: 团队正式批准另一套全局状态/路由架构，并完成迁移计划与回归验证。

## ADR-004: Use GetConnect and Base Repository for the App API data boundary

Status: Accepted

Context: App OpenAPI 快照包含 29 个 `/app/v1/**` 操作。后端在 HTTP 状态之外使用
`{code,msg,data}` 业务包装，受保护请求同时要求 Bearer token 和 clientId；各 Feature 的
DTO 演进速度不同，不能让页面或 Controller 复制这些规则。

Decision: App JSON 请求使用 GetX `GetConnect`，并通过 `BaseRemoteRepository` 统一处理 HTTP、
业务码、401 会话失效、JSON 校验和 `Result` 映射。只有 `code == 200` 是成功。token、clientId
和过期时间进入 `flutter_secure_storage`。请求监控只保存无敏感元数据。预签名对象存储的原始
字节 PUT 是唯一使用 `package:http` 的例外。

Reason: 将可复用的鉴权、错误和监控策略固定在跨 Feature 的稳定边界，同时让路径、请求体和
DTO 映射归各自业务域所有。

Alternatives: Controller 直接调用 GetConnect；每个 Repository 自行处理响应和会话；所有请求
统一使用 package:http；直接向 UI 返回动态 JSON。

Reconsider when: 后端删除统一包装或鉴权协议发生实质变化，或团队批准完成迁移方案的替代网络架构。
