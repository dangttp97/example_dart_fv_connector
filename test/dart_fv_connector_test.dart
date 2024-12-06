import 'package:dart_fv_connector/dart_fv_connector.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    SocketServer(3008);

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
  });
}
