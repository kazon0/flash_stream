import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants/transfer_constants.dart';
import '../core/errors/transfer_exception.dart';
import '../models/discovered_device.dart';
import '../models/transfer_event.dart';
import '../models/transfer_record.dart';
import '../models/transfer_status.dart';
import '../network/transfer_socket_service.dart';
import '../services/bonjour_discovery_service.dart';
import '../services/device_discovery_service.dart';
import '../services/file_action_service.dart';
import '../services/network_info_service.dart';
import '../storage/transfer_record_store.dart';

class TransferProvider extends ChangeNotifier {
  TransferProvider({
    required TransferSocketService socketService,
    required TransferRecordStore recordStore,
    NetworkInfoService networkInfoService = const NetworkInfoService(),
    FileActionService fileActionService = const FileActionService(),
    DeviceDiscoveryService? deviceDiscoveryService,
    BonjourDiscoveryService? bonjourDiscoveryService,
  }) : _socketService = socketService,
       _recordStore = recordStore,
       _networkInfoService = networkInfoService,
       _fileActionService = fileActionService,
       _deviceDiscoveryService =
           deviceDiscoveryService ?? DeviceDiscoveryService(),
       _bonjourDiscoveryService =
           bonjourDiscoveryService ?? BonjourDiscoveryService();

  final TransferSocketService _socketService;
  final TransferRecordStore _recordStore;
  final NetworkInfoService _networkInfoService;
  final FileActionService _fileActionService;
  final DeviceDiscoveryService _deviceDiscoveryService;
  final BonjourDiscoveryService _bonjourDiscoveryService;

  TransferStatus _status = TransferStatus.idle;
  TransferRecord? _currentRecord;
  double _progress = 0;
  int _transferredBytes = 0;
  int _totalBytes = 0;
  String _message = '准备就绪';
  bool _isListening = false;
  List<String> _localIps = const [];
  List<DiscoveredDevice> _discoveredDevices = const [];
  DiscoveredDevice? _selectedDevice;
  bool _isScanning = false;
  bool _hasScannedDevices = false;
  bool _disposed = false;

  TransferStatus get status => _status;
  TransferRecord? get currentRecord => _currentRecord;
  double get progress => _progress;
  int get transferredBytes => _transferredBytes;
  int get totalBytes => _totalBytes;
  String get message => _message;
  bool get isListening => _isListening;
  List<String> get localIps => List.unmodifiable(_localIps);
  List<DiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  DiscoveredDevice? get selectedDevice => _selectedDevice;
  bool get isScanning => _isScanning;
  bool get hasScannedDevices => _hasScannedDevices;

  Future<void> loadLocalIps() async {
    _localIps = await _networkInfoService.localIPv4Addresses();
    _safeNotifyListeners();
  }

  Future<void> startListening({
    int port = TransferConstants.defaultPort,
  }) async {
    try {
      await loadLocalIps();
      await _deviceDiscoveryService.startResponder(transferPort: port);
      await _bonjourDiscoveryService.startBroadcast(transferPort: port);
      await _socketService.startServer(port: port, onEvent: _applyEvent);
      _isListening = true;
      _safeNotifyListeners();
    } catch (error) {
      _applyEvent(
        TransferEvent(status: TransferStatus.failed, message: '监听失败: $error'),
      );
    }
  }

  Future<void> stopListening() async {
    await _bonjourDiscoveryService.stopBroadcast();
    await _deviceDiscoveryService.stopResponder();
    await _socketService.stopServer();
    _isListening = false;
    _status = TransferStatus.idle;
    _message = '已停止监听';
    _safeNotifyListeners();
  }

  void selectDevice(DiscoveredDevice device) {
    _selectedDevice = device;
    _message = '已选择 ${device.name}';
    _safeNotifyListeners();
  }

  Future<void> pickAndSendToSelectedDevice({
    int port = TransferConstants.defaultPort,
  }) async {
    final device = _selectedDevice;
    if (device == null) {
      _applyEvent(
        const TransferEvent(
          status: TransferStatus.failed,
          message: '请先选择接收方设备',
        ),
      );
      return;
    }

    _applyEvent(
      const TransferEvent(
        status: TransferStatus.selecting,
        message: '请选择要发送的文件',
      ),
    );

    final result = await FilePicker.pickFiles();
    final path = result?.files.single.path;
    if (path == null) {
      _applyEvent(
        const TransferEvent(status: TransferStatus.idle, message: '已取消选择文件'),
      );
      return;
    }

    try {
      await for (final event in _socketService.sendFile(
        ip: device.ip,
        port: device.port,
        file: File(path),
      )) {
        _applyEvent(event);
      }
    } on TransferException catch (error) {
      _applyEvent(
        TransferEvent(status: TransferStatus.failed, message: error.message),
      );
    } catch (error) {
      _applyEvent(
        TransferEvent(status: TransferStatus.failed, message: '发送异常: $error'),
      );
    }
  }

  Future<void> scanDevices() async {
    _isScanning = true;
    _hasScannedDevices = true;
    _message = '正在扫描局域网设备';
    _safeNotifyListeners();

    try {
      final results = await Future.wait([
        _bonjourDiscoveryService.scan(),
        _deviceDiscoveryService.scan(),
      ]);
      final devices = <String, DiscoveredDevice>{};
      for (final group in results) {
        for (final device in group) {
          devices[device.ip] = device;
        }
      }
      _discoveredDevices = devices.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (_selectedDevice != null &&
          !_discoveredDevices.any(
            (device) => device.ip == _selectedDevice!.ip,
          )) {
        _selectedDevice = null;
      }
      if (_selectedDevice == null && _discoveredDevices.length == 1) {
        _selectedDevice = _discoveredDevices.first;
      }
      _message = _discoveredDevices.isEmpty
          ? '未发现接收方'
          : '发现 ${_discoveredDevices.length} 台设备';
    } catch (error) {
      _message = '设备扫描失败: $error';
    } finally {
      _isScanning = false;
      _safeNotifyListeners();
    }
  }

  void _applyEvent(TransferEvent event) {
    _status = event.status;
    _currentRecord = event.record ?? _currentRecord;
    _progress = event.progress;
    _transferredBytes = event.transferredBytes;
    _totalBytes = event.totalBytes;
    _message = event.message ?? event.status.label;

    final record = event.record;
    if (record != null &&
        (event.status == TransferStatus.completed ||
            event.status == TransferStatus.failed)) {
      unawaited(_recordStore.upsert(record));
    }
    _safeNotifyListeners();
  }

  Future<String> openCurrentFile() {
    return _fileActionService.openFile(_currentRecord?.path);
  }

  Future<void> shareCurrentFile() {
    return _fileActionService.shareFile(_currentRecord?.path);
  }

  Future<String?> exportCurrentFile() {
    return _fileActionService.exportFile(_currentRecord?.path);
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_bonjourDiscoveryService.stopBroadcast());
    unawaited(_deviceDiscoveryService.stopResponder());
    unawaited(_socketService.stopServer());
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
