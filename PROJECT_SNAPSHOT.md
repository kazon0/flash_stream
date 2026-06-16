# FlashStream Project Snapshot

## Current Goal

Build the initial demo into a resume-consistent Flutter LAN P2P file transfer project with a clean architecture and demonstrable core features.

## Original Demo State

- Single page UI in `lib/views/transport_page.dart`.
- `ServerSocket` based receiver in `lib/network/network_service.dart`.
- Image-only sending through `image_picker`.
- Full file bytes loaded into memory before sending.
- No protocol metadata, progress model, MD5 verification, history storage, Provider state, or usable tests.

## Completed So Far

- Added dependencies:
  - `file_picker`
  - `path_provider`
  - `provider`
  - `hive`
  - `hive_flutter`
  - `crypto`
  - `convert`
- Added architecture directories:
  - `app`
  - `core`
  - `models`
  - `protocol`
  - `network`
  - `services`
  - `storage`
  - `providers`
  - `views/transfer`
  - `views/history`
- Added core models:
  - `TransferStatus`
  - `TransferDirection`
  - `TransferRecord`
  - `TransferEvent`
- Added protocol layer:
  - `TransferHeader`
  - `BinaryProtocol`
  - `PacketType`
- Added utilities:
  - `FileSizeFormatter`
  - `IpValidator`
  - `TransferException`
  - `TransferConstants`
- Added IO/network foundations:
  - `ChecksumService` using `Isolate.run`
  - `FileChunkService`
  - `RawSocketConnection`
  - `TransferSocketService` using protocolized `RawServerSocket` / `RawSocket`
  - `NetworkInfoService` for local IPv4 discovery
- Added Provider/UI/storage wiring:
  - `HiveTransferRecordStore`
  - `TransferProvider`
  - `HistoryProvider`
  - Provider-driven transfer page
  - Hive-backed history page
  - Async app initialization in `main.dart`
- Added this snapshot and `AGENTS.md` for future continuation.
- Removed the legacy demo files so the project has one active architecture.
- Replaced the default Flutter counter test with focused tests:
  - protocol header and resume offset encoding
  - file size formatting and IPv4 validation
  - transfer home page smoke rendering
- Added Android network permissions and iOS local network usage text.
- Added phone-to-phone run/test instructions to `README.md`.
- Migrated the network layer from `ServerSocket` / `Socket` to explicit `RawServerSocket` / `RawSocket`.
- Added receiver-side local IPv4 display chips for phone-to-phone testing.
- Added file actions:
  - completion card `打开` / `导出` / `分享`
  - history item `打开` / `导出` / `分享`
  - iOS Files app document visibility
- Fixed iOS keyboard dismissal on the transfer page.
- Fixed IP input to allow `.` on mobile keyboards.
- Added UDP LAN device discovery and receiver discovery responder.
- Added sender-side ACK wait, so 100% upload changes to a verification wait state until the receiver confirms save and MD5 success.
- Reworked the transfer status card into a file-style summary tile:
  - no long sandbox path in the main UI
  - file type icon and extension badge
  - tap completed file tile to open
- Added Bonjour/mDNS service discovery through `bonsoir`, with UDP broadcast retained as a fallback.
- Added iOS `NSBonjourServices` for `_flashstream._tcp`.
- Sender discovery results now show device name plus IP and fill the target IP when tapped.
- Removed manual IP input from the sender flow.
- Sender now uses `scan -> select device -> send file`.
- Receiver copy was changed to user-facing language without port/protocol details.
- Added provider cleanup on dispose and app detach to reduce iOS relaunch issues caused by leftover sockets/discovery services.
- Share actions are restored as direct actions at the user's request.
- Applied the referenced mobile UI direction:
  - oatmeal background
  - Morandi sage/slate/rose cards
  - softer 20-24px rounded controls
  - animated soft radar while scanning
  - gummy loading indicator for active transfer/listening states
  - file summary tile with type icon and extension badge
- Added `DeviceNameService` using `device_info_plus`:
  - Android broadcasts manufacturer/model when available
  - iOS broadcasts the user-visible device name when available
  - exact nearby hardware model names like AirDrop are not guaranteed by iOS privacy APIs
- Downgraded `device_info_plus` to `^10.1.2` because `12.4.0` required a newer iOS SDK API not available in the current Xcode toolchain.
- Fixed a likely iOS relaunch crash path:
  - removed async `context.read<TransferProvider>().stopListening()` from `AppLifecycleState.detached`
  - added safe `notifyListeners` guard after provider disposal
  - added Hive history box recovery on startup if the box cannot be opened
- Tightened the completed receive/send UI:
  - completed file card is still tappable to open
  - removed the extra `打开` button below completed files
  - kept `导出` and `分享` in one compact row
  - removed user-facing integrity-check wording from the sender status
- Unified the transfer page card colors:
  - status card and sender card now use the same slate-blue palette as the receiver card
  - app title was nudged slightly right and down for better visual balance
- Removed technical checksum wording from user-facing UI:
  - `完整性校验` / `MD5` / `校验` no longer appears in app-facing transfer status text
  - underlying checksum verification logic is still kept for reliability

## Verification

- `flutter analyze`: passed
- `flutter test`: passed
- `flutter build apk --debug`: passed, output `build/app/outputs/flutter-apk/app-debug.apk`
- `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --debug --no-codesign`: passed, output `build/ios/iphoneos/Runner.app`
- `flutter devices`: detected Android emulator, macOS, and Chrome; no physical Android/iPhone device was connected during this run.
- After adding file actions and discovery:
  - `flutter analyze`: passed
  - `flutter test`: passed
  - `flutter build apk --debug`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --debug --no-codesign`: passed
- After no-manual-IP UX update:
  - `flutter analyze`: passed
  - `flutter test`: passed
  - `flutter build apk --debug`: passed
- After Morandi UI and friendly device names:
  - `flutter analyze`: passed
  - `flutter test`: passed
  - `flutter build apk --debug`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --debug --no-codesign`: passed
- After iOS relaunch hardening:
  - `flutter analyze`: passed
  - `flutter test`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --debug --no-codesign`: passed
- After Bonjour/UI file-card update:
  - `flutter analyze`: passed
  - `flutter test`: passed
  - `flutter build apk --debug`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 pod install`: passed
  - `LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ios --debug --no-codesign`: passed
- After compact completed-file actions:
  - `dart format lib test`: passed
  - `flutter analyze`: passed
  - `flutter test`: passed
- After slate-blue card unification:
  - `dart format lib test`: passed
  - `flutter analyze`: passed
  - `flutter test`: passed
- After removing checksum wording from app UI:
  - `rg -n "完整性校验|校验|MD5" lib`: no matches
  - `dart format lib test`: passed
  - `flutter analyze`: passed
  - `flutter test`: passed

## Next Steps

1. Run a real Android-to-iPhone or iPhone-to-Android LAN test and record the result.
2. Add optional speed display.
3. Add an export/share action for received files.
4. Consider adding an FFI encryption placeholder only if the resume wording requires it.

## Important Notes

- The project root is:
  `/Users/zhengjinba/Documents/大三学习内容/flutter study/flash_stream`
- The Flutter project has been flattened to the Git repository root.
- Avoid overclaiming FFI encryption unless actual FFI integration is added.
