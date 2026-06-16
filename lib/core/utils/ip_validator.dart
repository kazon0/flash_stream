class IpValidator {
  const IpValidator._();

  static bool isValidIPv4(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 4) {
      return false;
    }
    for (final part in parts) {
      final number = int.tryParse(part);
      if (number == null || number < 0 || number > 255) {
        return false;
      }
    }
    return true;
  }
}
