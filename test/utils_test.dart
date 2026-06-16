import 'package:flash_stream/core/utils/file_size_formatter.dart';
import 'package:flash_stream/core/utils/ip_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats file sizes', () {
    expect(FileSizeFormatter.format(512), '512 B');
    expect(FileSizeFormatter.format(2048), '2.0 KB');
    expect(FileSizeFormatter.format(5 * 1024 * 1024), '5.0 MB');
  });

  test('validates IPv4 addresses', () {
    expect(IpValidator.isValidIPv4('192.168.1.2'), isTrue);
    expect(IpValidator.isValidIPv4('256.168.1.2'), isFalse);
    expect(IpValidator.isValidIPv4('localhost'), isFalse);
  });
}
