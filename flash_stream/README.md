# FlashStream

FlashStream is a Flutter LAN peer-to-peer file transfer app. It focuses on large-file transfer ergonomics: RawSocket networking, chunked file IO, progress events, resumable partial files, MD5 verification, Provider-driven UI state, and Hive-backed local transfer history.

## Features

- LAN point-to-point file transfer over `RawServerSocket` / `RawSocket`.
- Custom binary-framed JSON header with file metadata.
- Chunked file reading and writing instead of loading the whole payload into memory.
- Resume support through `.part` temporary files and offset negotiation.
- MD5 checksum calculation in a background isolate.
- Stream-style transfer events for sending, receiving, verifying, completed, and failed states.
- Provider-based state management.
- Hive-backed transfer history and keyword search.
- Receiver-side local IPv4 display and UDP LAN device discovery.
- Open, export, or share received files from the completion card and history page.
- Clean layered structure for protocol, network, services, storage, providers, and views.

## Architecture

```text
lib/
  app/          App shell and theme
  core/         Constants, errors, utilities
  models/       Transfer records, status, direction, events
  protocol/     Header and binary frame encoding/decoding
  network/      RawSocket transfer service and stream reader
  services/     File chunks and checksum work
  storage/      Hive transfer record store
  providers/    Transfer and history state controllers
  views/        Transfer and history pages
```

## Transfer Flow

1. Receiver starts listening on port `9527`.
2. Sender selects a file and inputs the receiver IPv4 address.
3. Sender calculates the source file MD5 in an isolate.
4. Sender writes a framed metadata header to the socket.
5. Receiver checks whether a partial file already exists and returns the resume offset.
6. Sender continues from that offset and streams file chunks.
7. Receiver appends chunks to a `.part` file and reports progress.
8. Receiver verifies the final MD5 and renames the `.part` file to the original file name.
9. Receiver returns an ACK to the sender after the file is saved and verified.
10. Completed or failed transfer records are persisted to Hive.

## Resume-Safe Project Description

> Built a Flutter LAN P2P file transfer app with a layered architecture. The project uses `RawServerSocket` / `RawSocket` to implement the network channel, and supports a custom transfer header protocol, chunked file IO, resumable partial-file transfer, isolate-based MD5 verification, Provider state management, Stream-style progress events, and Hive-backed transfer history search.

## Run

Enter the project root:

```bash
cd "/Users/zhengjinba/Documents/大三学习内容/flutter study/flash_stream/flash_stream"
```

Install dependencies:

```bash
flutter pub get
```

List connected devices:

```bash
flutter devices
```

Run on a specific Android or iOS device:

```bash
flutter run -d <device-id>
```

Run on macOS for quick desktop smoke testing when no phone is connected:

```bash
flutter run
```

## Phone-to-Phone Test

1. Put both phones on the same Wi-Fi network, or connect one phone to the other's hotspot.
2. Connect the first phone by USB and run:
   ```bash
   flutter devices
   flutter run -d <receiver-device-id>
   ```
3. Connect the second phone by USB and run the app on it as well:
   ```bash
   flutter run -d <sender-device-id>
   ```
4. On the receiving phone, tap `开始接收`.
5. The receiving phone will show one or more local IPv4 chips, such as `192.168.1.23`.
6. On the sending phone, tap `自动发现设备`.
7. If a device chip appears, tap it to fill the IP. If discovery fails, manually enter the receiver IPv4 address.
8. Tap `选择文件并发送`.
9. Select a file and keep both apps in the foreground until the transfer finishes.
10. After completion, use `打开`, `导出`, or `分享` to view or move the received file.
11. Open the history page from the top-right history icon to check completed or failed records. Each history item supports `打开`, `导出`, and `分享`.

Notes:

- iOS will show a local network permission prompt. Allow it.
- Android and iOS must be on the same subnet. If Wi-Fi client isolation is enabled, use a phone hotspot instead.
- If multiple IPv4 addresses appear, prefer the Wi-Fi or hotspot address, usually starting with `192.168`, `172.20`, or `10`.
- The default transfer port is `9527`.

Current storage behavior: the receiver first saves files into the app documents directory. Use `打开` to preview with a system app, `导出` to save to a user-selected visible location, or `分享` to send the file through the system share sheet. On iOS, the app documents directory is also exposed in the Files app.

## Verify

```bash
flutter analyze
flutter test
```
