# FlashStream Test Report

Date: 2026-06-16

## Summary

FlashStream currently passes static analysis and all automated tests. The latest benchmark also confirms that moving large-file chunk IO and MD5 work to isolates significantly reduces UI isolate event-loop blocking.

## Verification Commands

```bash
flutter analyze
flutter test
dart run tool/main_isolate_load_benchmark.dart 128
```

## Results

### Static Analysis

```text
Analyzing flash_stream...
No issues found! (ran in 6.5s)
```

### Automated Tests

```text
All tests passed!
```

Covered areas:

- RawSocket exact-byte read/write behavior.
- Binary protocol header encode/decode.
- Resume offset encode/decode.
- Stable transfer task ID generation from file identity.
- Isolate-backed chunked file reading from a non-zero offset.
- Isolate-backed chunked file writing.
- File size formatting and IPv4 validation utilities.
- Transfer home page smoke rendering.

### Main-Isolate Load Benchmark

Command:

```bash
dart run tool/main_isolate_load_benchmark.dart 128
```

Payload: 128MB generated local binary file.

Output:

```text
main-isolate sync chunk IO + MD5: elapsed=6452ms, blocked=6386ms, maxDelay=6385ms
worker-isolate chunk IO + MD5: elapsed=2921ms, blocked=25ms, maxDelay=7ms
Main-isolate event-loop blocking reduction: 99.6%
```

Benchmark metric:

- A 16ms periodic timer runs on the main isolate while the workload executes.
- `blocked` is accumulated timer delay beyond the expected 16ms cadence.
- This measures UI isolate responsiveness, not total device CPU usage.

## Interview-Safe Explanation

The resume statement about reducing main-thread load should be explained as UI isolate event-loop blocking reduction, not total CPU reduction.

Suggested wording:

> I measured this with a local benchmark that compares a synchronous main-isolate chunk IO + MD5 baseline against the current worker-isolate chunk IO + MD5 path. The metric is accumulated delay beyond a 16ms timer on the UI isolate. On a 128MB sample file, the baseline blocked the event loop for 6386ms, while the isolate-backed version blocked for 25ms, which is a 99.6% reduction. I state 60% conservatively because the exact number depends on device and file size.

## Current Implementation Notes

- Sending path uses isolate-backed chunked reads.
- Receiving path uses isolate-backed chunked writes to `.part` files.
- MD5 checksum calculation runs in an isolate.
- Resume is based on stable task IDs generated from file name, file size, and MD5.
- Receiver validates `.part` size before resuming and deletes corrupted partial files after MD5 mismatch.
