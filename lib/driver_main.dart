// lib/driver_main.dart
// Entry point for Flutter Driver integration testing and MCP tooling

import 'package:flutter_driver/driver_extension.dart';
import 'main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
