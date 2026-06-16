enum TransferDirection {
  send,
  receive;

  String get label => switch (this) {
    TransferDirection.send => '发送',
    TransferDirection.receive => '接收',
  };
}
