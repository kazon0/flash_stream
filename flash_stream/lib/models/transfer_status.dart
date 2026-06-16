enum TransferStatus {
  idle,
  listening,
  selecting,
  hashing,
  connecting,
  sending,
  receiving,
  verifying,
  completed,
  failed,
  cancelled;

  String get label => switch (this) {
    TransferStatus.idle => '准备就绪',
    TransferStatus.listening => '等待接收',
    TransferStatus.selecting => '选择文件',
    TransferStatus.hashing => '准备文件',
    TransferStatus.connecting => '连接中',
    TransferStatus.sending => '发送中',
    TransferStatus.receiving => '接收中',
    TransferStatus.verifying => '保存中',
    TransferStatus.completed => '已完成',
    TransferStatus.failed => '失败',
    TransferStatus.cancelled => '已取消',
  };
}
