class TransferException implements Exception {
  const TransferException(this.message);

  final String message;

  @override
  String toString() => message;
}
