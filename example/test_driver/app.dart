// Entrypoint that runs the example app with the Flutter Driver extension
// enabled, so it can be driven by flutter_driver (e.g. the Dart MCP server).
//
//   flutter run -d windows -t test_driver/app.dart
import 'package:flutter_driver/driver_extension.dart';
import 'package:onnxruntime_example/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
