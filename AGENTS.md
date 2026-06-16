# FlashStream Agent Guide

## Project Goal

FlashStream is a Flutter-based LAN P2P file transfer app. The resume-facing target is a high-performance multimedia/file transfer system using Dart Socket APIs, Provider, Hive, Stream-based progress events, Isolate-backed checksum work, chunked file IO, MD5 verification, and basic resumable transfer.

## Engineering Rules

- Keep the project runnable after each change.
- Prefer small, verifiable steps over large rewrites.
- Do not put socket, file IO, or persistence logic directly in widgets.
- UI should consume Provider state and call Provider actions only.
- Use chunked reads/writes for files. Do not use `readAsBytes()` for transfer payloads.
- Expensive checksum work must run outside the UI isolate.
- Store transfer history through the storage layer, not from widgets.
- Add or update tests when protocol, model serialization, or utility behavior changes.

## Intended Architecture

```text
lib/
  app/          App shell and theme
  core/         Constants, errors, utilities
  models/       Transfer records, status, direction, events
  protocol/     Binary protocol header encoding/decoding
  network/      RawSocket transfer service and stream reader
  services/     File chunks, checksum, resume helpers
  storage/      Hive-backed transfer history
  providers/    Provider state controllers
  views/        Flutter pages and widgets
```

## Resume Scope

Keep claims aligned with implemented code:

- Implemented now: `RawServerSocket` / `RawSocket` transfer, binary header protocol, chunked file IO, Stream progress, Provider state, Hive history, Isolate MD5, local IPv4 discovery, and basic resume via partial files.
- If FFI encryption is not implemented, describe it only as a reserved extension point.

## Verification Commands

Run these before calling the project complete:

```bash
flutter analyze
flutter test
```
