class TransferConstants {
  const TransferConstants._();

  static const int defaultPort = 9527;
  static const int chunkSize = 64 * 1024;
  static const String hiveBoxName = 'transfer_records';
  static const String partialExtension = '.part';
}
