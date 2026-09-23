# rhythm/domain/repositories 目录

包含节奏读取、创建、更新和删除的 Repository 抽象及输入值对象。

接口不暴露 REST、数据库或 BLE 类型；具体实现归 `rhythm/data`。

文件职责：

- `rhythm_repository.dart`：定义节奏列表、详情、创建、更新和删除接口，以及新增/更新请求值对象。
