# control data

控制数据层只把语义指令交给共享 `cyberskin_device_sdk`。具体设备协议、校验和、帧序列与 BLE 写入由 SDK 所有；这里不保存 FlutterBluePlus 对象，也不拼接十六进制帧。
