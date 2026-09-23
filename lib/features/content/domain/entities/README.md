# content/domain/entities 目录

包含后台内容的不可变领域模型。

模型保留开放字符串字段，不根据 OpenAPI 描述文本擅自收窄为枚举。

文件职责：

- `app_content.dart`：定义协议兼容的应用协议、功能开关、CMS 页面和广告位不可变模型。
