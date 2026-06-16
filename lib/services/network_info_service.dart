import 'dart:io';

class NetworkInfoService {
  const NetworkInfoService();

  Future<List<String>> localIPv4Addresses() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final addresses = <String>[];
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) {
          addresses.add(address.address);
        }
      }
    }
    return addresses;
  }
}
