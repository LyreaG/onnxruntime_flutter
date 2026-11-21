// Runs against test_driver/app.dart:
//
//   flutter drive -d windows -t test_driver/app.dart
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  late FlutterDriver driver;
  final result = find.byValueKey('result');

  setUpAll(() async => driver = await FlutterDriver.connect());
  tearDownAll(() async => driver.close());

  // flutter_driver has no "text contains" finder, so poll the result text.
  Future<String> waitForResult(String prefix) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (true) {
      final text = await driver.getText(result);
      if (text.startsWith(prefix)) return text;
      if (DateTime.now().isAfter(deadline)) {
        fail('Timed out waiting for "$prefix", last result: "$text"');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<String> tapAndRead(String button, String prefix) async {
    await driver.tap(find.text(button));
    return waitForResult(prefix);
  }

  test('model loads', () async {
    await waitForResult('Ready');
  });

  test('Mode Type Test returns every type', () async {
    final text = await tapAndRead('Mode Type Test', 'Type test done');
    expect(text.split('\n'), hasLength(5));
  });

  test('VAD finds the speech segment', () async {
    final text = await tapAndRead('VAD', 'VAD done');
    expect(text, contains('Speech: 3.072-3.584s'));
  });

  test('VAD Concurrency gives the same segment', () async {
    final text = await tapAndRead('VAD Concurrency', 'VAD done');
    expect(text, contains('Speech: 3.072-3.584s'));
  });
}
