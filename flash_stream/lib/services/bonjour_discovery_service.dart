import 'dart:async';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';

import '../core/constants/transfer_constants.dart';
import '../models/discovered_device.dart';
import 'device_name_service.dart';

class BonjourDiscoveryService {
  BonjourDiscoveryService({DeviceNameService? deviceNameService})
    : _deviceNameService = deviceNameService ?? DeviceNameService();

  static const String serviceType = '_flashstream._tcp';

  final DeviceNameService _deviceNameService;
  BonsoirBroadcast? _broadcast;

  Future<void> startBroadcast({
    int transferPort = TransferConstants.defaultPort,
  }) async {
    await stopBroadcast();
    final deviceName = await _deviceNameService.friendlyName();
    final service = BonsoirService(
      name: deviceName,
      type: serviceType,
      port: transferPort,
      attributes: const {'app': 'FlashStream'},
    );
    final broadcast = BonsoirBroadcast(service: service, printLogs: false);
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;
  }

  Future<void> stopBroadcast() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  Future<List<DiscoveredDevice>> scan({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final localIps = await _localIPv4Addresses();
    final discovery = BonsoirDiscovery(type: serviceType, printLogs: false);
    final devices = <String, DiscoveredDevice>{};
    final completer = Completer<List<DiscoveredDevice>>();

    await discovery.initialize();
    final subscription = discovery.eventStream?.listen((event) async {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        await discovery.serviceResolver.resolveService(event.service);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;
        final ip = await _resolveServiceIp(service.host, localIps);
        if (ip == null || localIps.contains(ip)) {
          return;
        }
        devices[ip] = DiscoveredDevice(
          name: service.name,
          ip: ip,
          port: service.port,
        );
      }
    });

    await discovery.start();
    Timer(timeout, () async {
      await subscription?.cancel();
      await discovery.stop();
      if (!completer.isCompleted) {
        completer.complete(devices.values.toList());
      }
    });

    return completer.future;
  }

  Future<String?> _resolveServiceIp(String? host, List<String> localIps) async {
    if (host == null || host.isEmpty) {
      return null;
    }
    final parsed = InternetAddress.tryParse(host);
    if (parsed != null && parsed.type == InternetAddressType.IPv4) {
      return parsed.address;
    }
    final addresses = await InternetAddress.lookup(
      host,
      type: InternetAddressType.IPv4,
    );
    for (final address in addresses) {
      if (!address.isLoopback && !localIps.contains(address.address)) {
        return address.address;
      }
    }
    return null;
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
}
