import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceNameService {
  DeviceNameService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<String> friendlyName() async {
    try {
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        final manufacturer = _clean(info.manufacturer);
        final model = _clean(info.model);
        if (manufacturer.isNotEmpty &&
            model.isNotEmpty &&
            !model.toLowerCase().contains(manufacturer.toLowerCase())) {
          return '$manufacturer $model';
        }
        if (model.isNotEmpty) {
          return model;
        }
      }

      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        final name = _clean(info.name);
        if (name.isNotEmpty) {
          return name;
        }
        final machine = _clean(info.utsname.machine);
        return machine.isEmpty ? 'iPhone' : machine;
      }

      if (Platform.isMacOS) {
        final info = await _plugin.macOsInfo;
        final name = _clean(info.computerName);
        if (name.isNotEmpty) {
          return name;
        }
      }
    } catch (_) {
      // Fall back to hostname below.
    }

    return Platform.localHostname.isEmpty
        ? 'FlashStream 设备'
        : Platform.localHostname;
  }

  String _clean(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
