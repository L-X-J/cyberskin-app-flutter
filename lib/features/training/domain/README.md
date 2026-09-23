# training/domain 目录

子目录与文件：

- `entities/`：课程、阶段和 customMode 模型；见 `entities/README.md`。
- `repositories/`：训练课程访问抽象；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

训练功能的领域层预留目录，当前尚无实现。

后续放置训练课程、阶段、进度和运行状态等纯 Dart 模型及数据访问契约。训练流程规则
应在此独立测试，不依赖 Flutter 或具体 BLE 插件。
