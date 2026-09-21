# Known Issues

## Flutter cache write permission

Symptom: `fvm flutter --version` 可能在 `/Users/cxl/fvm/versions/3.47.5/bin/cache` 写入 `engine.stamp.tmp` / `engine.realm` 时报告 `Operation not permitted`。

Cause: 当前执行环境对 FVM 安装目录的写权限受限。

Resolution: 优先使用仓库锁定版本的 Dart/Flutter 可执行文件；若需要刷新 FVM 引擎缓存，应在本机终端修复该目录权限后重试。不要把缓存路径或权限 workaround 写入项目代码。

Important: 该问题是环境问题，不代表项目源码无法通过分析或测试。
