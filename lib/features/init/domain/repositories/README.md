# init/domain/repositories 目录

初始化流程复用 `content/domain` 的 `ContentRepository`，不在此复制启动配置访问契约。

如后续出现与内容无关的初始化资源，应为其所属业务域建立独立 Repository，再由 InitController
编排，避免形成无边界初始化接口。
