import 'transfer_record.dart';
import 'transfer_status.dart';

class TransferEvent {
  const TransferEvent({
    required this.status,
    this.record,
    this.progress = 0,
    this.transferredBytes = 0,
    this.totalBytes = 0,
    this.message,
  });

  final TransferStatus status;
  final TransferRecord? record;
  final double progress;
  final int transferredBytes;
  final int totalBytes;
  final String? message;
}
