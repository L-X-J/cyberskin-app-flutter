# App OpenAPI 静态文档

`app-openapi.json` 是 App 分组（SpringDoc 分组名 `App接口`）的 OpenAPI 3.1 静态导出，覆盖 `/app/v1/**` 全部接口与请求/响应 schema。

这份文件是导出快照，不是接口定义的真相源。真相源是 Controller / BO / VO 上的注解，由 SpringDoc 在应用启动时生成运行时文档。

## 什么时候需要重新生成

App 契约发生变化时：

- 新增或删除 Controller 方法
- 修改 `@Operation` / `@Schema` / Bean Validation 注解
- 调整请求 BO 或响应 VO 字段

只改源码不重启时，Swagger 与导出文件都还是旧内容。

## 重新生成步骤

```bash
# 1. Java 21 重新打包
JAVA_HOME=/Users/cxl/Library/Java/JavaVirtualMachines/ms-21.0.8/Contents/Home \
  ./mvnw -pl ruoyi-admin -am -DskipTests package

# 2. 重启后端
JAVA_HOME=/Users/cxl/Library/Java/JavaVirtualMachines/ms-21.0.8/Contents/Home \
  java -jar ruoyi-admin/target/ruoyi-admin.jar --server.port=8090 --spring.profiles.active=dev

# 3. 导出静态文档
python3 scripts/export_app_openapi.py
```

导出脚本默认抓取 `http://127.0.0.1:8090/v3/api-docs/App接口`，输出到 `docs/openapi/app-openapi.json`。

文档里的 `servers[0].url` 默认是导出时运行实例的地址（通常是 `http://127.0.0.1:8090`）。对外分发时用 `--server-url` 覆盖：

```bash
python3 scripts/export_app_openapi.py --server-url https://api.example.com
```

## 鉴权声明

SpringDoc 不输出 Sa-Token 的鉴权信息，脚本会自行补齐，否则客户端生成器无法产出带鉴权的调用代码：

- `components.securitySchemes` 增加 `AppToken`（`Authorization: Bearer <token>`）与 `ClientId`（`clientid` 请求头）
- 受保护接口标注 `security: [{AppToken: []}, {ClientId: []}]`
- 公开接口标注 `security: []`，覆盖全局鉴权要求

区分依据是 SpringDoc 渲染进 `description` 的 Sa-Token 注解：带 `忽略权限检查`（源码 `@SaIgnore`）的判为公开接口，其余判为需登录。当前导出结果为公开 15 个、需鉴权 15 个。

调整 Controller 上的 `@SaIgnore` / `@SaCheckLogin` 后必须重新导出，`security` 字段才会同步。

## 校验方式

```bash
# 分组可访问
curl http://127.0.0.1:8090/v3/api-docs/App接口

# 导出文件结构有效
jq '.paths | length' docs/openapi/app-openapi.json
```

Swagger UI 入口：`http://127.0.0.1:8090/swagger-ui/index.html`，右上角选择 `App接口`。
