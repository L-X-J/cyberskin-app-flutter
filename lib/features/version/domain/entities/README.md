# version/domain/entities 目录

文件职责：

- `version_check.dart`：定义平台、版本号、最低支持版本、强制升级、更新说明和安装地址模型。

包含 App 版本检查的不可变领域模型。

`forceUpdate` 和 `hasUpdate` 缺失时按 false 解释，避免错误触发升级流程。
