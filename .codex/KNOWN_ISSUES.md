# Known Issues

## Flutter cache write permission

Symptom: `fvm flutter --version` 可能在 `/Users/cxl/fvm/versions/3.47.5/bin/cache` 写入 `engine.stamp.tmp` / `engine.realm` 时报告 `Operation not permitted`。

Cause: 当前执行环境对 FVM 安装目录的写权限受限。

Resolution: 优先使用仓库锁定版本的 Dart/Flutter 可执行文件；若需要刷新 FVM 引擎缓存，应在本机终端修复该目录权限后重试。不要把缓存路径或权限 workaround 写入项目代码。

Important: 该问题是环境问题，不代表项目源码无法通过分析或测试。

## 无限 Lottie 背景与 `pumpAndSettle`

Symptom: 页面挂载 `AppLottieBackground` 后，测试中的 `tester.pumpAndSettle()` 会超时；即使背景视觉效果稳定，Flutter 测试仍会等待永不结束的动画 ticker。

Cause: `AppLottieBackground` 按产品契约内部无限循环，测试框架无法自动判定这类持续动画已经“静止”。

Resolution: 存在无限背景的 Widget 测试应使用固定次数的 `tester.pump(...)` 或 `pump(duration)` 推进到目标状态，不要使用 `pumpAndSettle()`；只有先卸载背景或禁用动画的测试才能使用 `pumpAndSettle()`。不得为了测试方便移除组件的无限循环契约。

Important: 这是无限动画的预期测试语义，不是页面卡死或组件未完成加载。
