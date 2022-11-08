import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class LedgerOptions {
  final Duration maxScanDuration;
  final Duration prescanDuration;
  final Duration connectionTimeout;
  final ScanMode scanMode;

  LedgerOptions({
    this.maxScanDuration = const Duration(milliseconds: 15000),
    this.prescanDuration = const Duration(seconds: 5),
    this.connectionTimeout = const Duration(seconds: 2),
    this.scanMode = ScanMode.lowPower,
  });
}
