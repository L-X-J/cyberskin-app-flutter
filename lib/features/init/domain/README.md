# init/domain 目录

初始化 Feature 当前不定义独立领域模型；启动配置属于 `content` 业务域，初始化流程只编排
`ContentRepository`。后续出现稳定的初始化专属规则时再在此建立模型和抽象，避免提前抽象。
