import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/constants/transfer_constants.dart';
import '../models/discovered_device.dart';
import 'device_name_service.dart';

class DeviceDiscoveryService {
  DeviceDiscoveryService({DeviceNameService? deviceNameService})
    : _deviceNameService = deviceNameService ?? DeviceNameService();

  static const int discoveryPort = 9528;
  static const String _probe = 'FLASH_STREAM_DISCOVER';
  static const String _prefix = 'FLASH_STREAM_HERE';

  final DeviceNameService _deviceNameService;
  RawDatagramSocket? _responder;

  Future<void> startResponder({
    int transferPort = TransferConstants.defaultPort,
  }) async {
    await stopResponder();
    _responder = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: true,
    );
    _responder!.broadcastEnabled = true;
    final deviceName = await _deviceNameService.friendlyName();
    _responder!.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final datagram = _responder!.receive();
      if (datagram == null) {
        return;
      }
      final message = utf8.decode(datagram.data, allowMalformed: true);
      if (message != _probe) {
        return;
      }
      final response = '$_prefix|$deviceName|$transferPort';
      _responder!.send(utf8.encode(response), datagram.address, datagram.port);
    });
  }

  Future<void> stopResponder() async {
    _responder?.close();
    _responder = null;
  }

  Future<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final localIps = await _localIPv4Addresses();
    final broadcastAddresses = {
      InternetAddress('255.255.255.255'),
      for (final ip in localIps) InternetAddress(_directedBroadcastFor(ip)),
    };
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
      reusePort: true,
    );
    socket.broadcastEnabled = true;
    final devices = <String, DiscoveredDevice>{};
    final completer = Completer<List<DiscoveredDevice>>();
    late final StreamSubscription<RawSocketEvent> subscription;

    subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) {
        return;
      }
      final datagram = socket.receive();
      if (datagram == null) {
        return;
      }
      final message = utf8.decode(datagram.data, allowMalformed: true);
      final parts = message.split('|');
      if (parts.length != 3 || parts.first != _prefix) {
        return;
      }
      final port = int.tryParse(parts[2]);
      if (port == null) {
        return;
      }
      if (localIps.contains(datagram.address.address)) {
        return;
      }
      devices[datagram.address.address] = DiscoveredDevice(
        name: parts[1],
        ip: datagram.address.address,
        port: port,
      );
    });

    final probe = utf8.encode(_probe);
    for (final address in broadcastAddresses) {
      socket.send(probe, address, discoveryPort);
    }

    Timer(timeout, () async {
      await subscription.cancel();
      socket.close();
      if (!completer.isCompleted) {
        completer.complete(devices.values.toList());
      }
    });

    return completer.future;
  }

  Future<List<String>> _localIPv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    return [
      for (final interface in interfaces)
        for (final address in interface.addresses)
          if (!address.isLoopback) address.address,
    ];
  }

  String _directedBroadcastFor(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) {
      return '255.255.255.255';
    }
    return '${parts[0]}.${parts[1]}.${parts[2]}.255';
  }
}
