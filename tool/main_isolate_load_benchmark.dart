import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flash_stream/core/constants/transfer_constants.dart';
import 'package:flash_stream/services/checksum_service.dart';
import 'package:flash_stream/services/file_chunk_service.dart';

Future<void> main(List<String> args) async {
  final sizeMb = args.isEmpty ? 128 : int.parse(args.first);
  final tempDir = await Directory.systemTemp.createTemp('flash_stream_bench_');
  final source = File('${tempDir.path}/source.bin');
  final syncCopy = File('${tempDir.path}/sync-copy.bin');
  final isolateCopy = File('${tempDir.path}/isolate-copy.bin');

  try {
    stdout.writeln('Preparing ${sizeMb}MB payload...');
    await _createPayload(source, sizeMb: sizeMb);

    final syncResult = await _measure(
      label: 'main-isolate sync chunk IO + MD5',
      workload: () => _syncCopyAndMd5(source, syncCopy),
    );
    final isolateResult = await _measure(
      label: 'worker-isolate chunk IO + MD5',
      workload: () => _isolateCopyAndMd5(source, isolateCopy),
    );

    final reduction = syncResult.blockedMs == 0
        ? 0.0
        : (syncResult.blockedMs - isolateResult.blockedMs) /
              syncResult.blockedMs *
              100;

    stdout
      ..writeln('')
      ..writeln('Result')
      ..writeln('------')
      ..writeln(syncResult)
      ..writeln(isolateResult)
      ..writeln(
        'Main-isolate event-loop blocking reduction: '
        '${reduction.toStringAsFixed(1)}%',
      )
      ..writeln('')
      ..writeln(
        'Metric: accumulated delay beyond a 16ms periodic timer while the '
        'workload is running. This measures UI-isolate responsiveness, not '
        'total device CPU usage.',
      );
  } finally {
    await tempDir.delete(recursive: true);
  }
}

Future<void> _createPayload(File file, {required int sizeMb}) async {
  final random = Random(42);
  final raf = await file.open(mode: FileMode.write);
  try {
    final buffer = List<int>.generate(
      TransferConstants.chunkSize,
      (_) => random.nextInt(256),
    );
    final iterations = sizeMb * 1024 * 1024 ~/ buffer.length;
    for (var i = 0; i < iterations; i++) {
      await raf.writeFrom(buffer);
    }
  } finally {
    await raf.close();
  }
}

Future<BenchmarkResult> _measure({
  required String label,
  required Future<void> Function() workload,
}) async {
  final probe = _EventLoopProbe();
  final watch = Stopwatch()..start();
  probe.start();
  await workload();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  probe.stop();
  watch.stop();

  return BenchmarkResult(
    label: label,
    elapsedMs: watch.elapsedMilliseconds,
    blockedMs: probe.blockedMs,
    maxDelayMs: probe.maxDelayMs,
  );
}

Future<void> _syncCopyAndMd5(File source, File target) async {
  final input = source.openSync();
  final output = target.openSync(mode: FileMode.write);
  final sink = AccumulatorSink<Digest>();
  final conversion = md5.startChunkedConversion(sink);

  try {
    final buffer = List<int>.filled(TransferConstants.chunkSize, 0);
    while (true) {
      final read = input.readIntoSync(buffer);
      if (read == 0) {
        break;
      }
      final bytes = buffer.sublist(0, read);
      conversion.add(bytes);
      output.writeFromSync(bytes);
    }
    conversion.close();
    sink.events.single.toString();
  } finally {
    input.closeSync();
    output.closeSync();
  }
}

Future<void> _isolateCopyAndMd5(File source, File target) async {
  await const ChecksumService().calculateMd5(source.path);
  final writer = await const FileChunkService().openChunkedWrite(
    target,
    mode: FileMode.write,
  );
  try {
    await for (final chunk in const FileChunkService().openChunkedRead(
      source,
    )) {
      await writer.write(chunk);
    }
  } finally {
    await writer.close();
  }
}

class _EventLoopProbe {
  static const _period = Duration(milliseconds: 16);

  Timer? _timer;
  DateTime? _expectedNextTick;
  var blockedMs = 0;
  var maxDelayMs = 0;

  void start() {
    _expectedNextTick = DateTime.now().add(_period);
    _timer = Timer.periodic(_period, (_) {
      final now = DateTime.now();
      final expected = _expectedNextTick!;
      final delay = now.difference(expected).inMilliseconds;
      if (delay > 0) {
        blockedMs += delay;
        if (delay > maxDelayMs) {
          maxDelayMs = delay;
        }
      }
      _expectedNextTick = now.add(_period);
    });
  }

  void stop() {
    _timer?.cancel();
  }
}

class BenchmarkResult {
  const BenchmarkResult({
    required this.label,
    required this.elapsedMs,
    required this.blockedMs,
    required this.maxDelayMs,
  });

  final String label;
  final int elapsedMs;
  final int blockedMs;
  final int maxDelayMs;

  @override
  String toString() {
    return '$label: elapsed=${elapsedMs}ms, '
        'blocked=${blockedMs}ms, maxDelay=${maxDelayMs}ms';
  }
}
