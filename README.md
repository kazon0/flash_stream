# FlashStream

FlashStream 是一个基于 Flutter 的局域网 P2P 文件传输应用，支持 Android 与 iOS 在同一局域网内发现附近设备、选择文件、分块传输、校验落盘，并保留本地历史记录。

## 功能

- 附近设备发现
  - Bonjour/mDNS 发现
  - UDP 广播发现
  - 发送端选择附近设备
- 单文件传输
  - 发送端选择文件
  - 接收端开启接收
  - 建立 `RawSocket` 直连后传输
- 分块读写
  - 256KB chunk 流式处理
  - 文件分块读取、分块写入与 MD5 校验放到 isolate 执行
- 可靠性
  - `.part` 临时文件续传
  - MD5 校验
  - ACK 回执确认接收端保存完成
- 本地记录与文件操作
  - Hive 存储传输历史
  - 支持搜索历史记录
  - 已接收文件支持 `打开`、`导出`、`分享`
  - 移动端导出通过原生流式文件写出，避免大文件整包读入内存

## 技术栈

- Flutter
- Dart
- Provider
- Hive
- `RawServerSocket` / `RawSocket`
- Isolate
- `crypto`

## 项目结构

```text
lib/
  app/          应用入口、主题、配色
  core/         常量、异常、通用工具
  models/       传输记录、状态、事件模型
  protocol/     二进制协议与 header 编解码
  network/      RawSocket 网络层
  services/     文件分块、校验、设备发现
  storage/      Hive 历史记录存储
  providers/    业务状态控制
  views/        页面与组件
```

## 传输流程

1. 接收端开启接收。
2. 发送端扫描附近设备并选择目标设备。
3. 发送端选择文件，在 isolate 中计算源文件 MD5。
4. 双方通过自定义 header 交换文件名、大小、MD5、taskId。
5. 接收端检查是否存在同任务的 `.part` 文件，并返回续传 offset。
6. 发送端从 offset 开始在 isolate 中按块读取文件并写入 socket。
7. 接收端通过 isolate 按块写入 `.part` 文件。
8. 接收完成后重新计算 MD5，校验成功后重命名为正式文件。
9. 接收端返回 ACK，发送端标记任务完成。
10. 成功或失败记录写入 Hive。

## 运行

```bash
cd flash_stream
flutter pub get
flutter devices
flutter run -d <device-id>
```

桌面调试可直接运行：

```bash
flutter run
```

## 真机测试

1. 两台手机连接同一个 Wi-Fi，或者一台开热点、另一台连接热点。
2. 接收端打开 App，切到“接收”，点击开启接收。
3. 发送端打开 App，切到“发送”，点击查找附近设备。
4. 选择扫描到的设备并发送文件。
5. 接收完成后，可直接打开文件，或导出、分享。

### iOS

- 首次运行会弹出本地网络权限，请允许。
- 真机调试需要在 Xcode 中配置开发签名。

### Android

- 调试安装可直接使用 `flutter run` 或 Android Studio。
- 如果需要分发安装，需要额外打包签名 APK。

## 文件保存

- 接收端首先把文件保存到应用可管理目录。
- 可以通过 `打开` 直接预览。
- 如果希望在系统文件管理器中长期可见，使用 `导出`。
- Android 的 `导出` 会通过原生 MediaStore 写入系统 `Downloads/FlashStream` 目录。
- iOS 的 `导出` 会打开系统“存储到文件”选择器，由用户选择 iCloud Drive、我的 iPhone 或其他文件夹作为保存位置。
- 移动端导出不会使用 `readAsBytes()` 把大文件整包读入 Dart 内存。
- macOS / Windows / Linux 的 `导出` 会选择目标路径，并使用分块复制写出文件。
- `分享` 适合转发到其他 App。

## 验证

```bash
flutter analyze
flutter test
```
