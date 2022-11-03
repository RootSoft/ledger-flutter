import 'package:ledger_flutter/src/ledger.dart';

class LedgerOptions {
  final int maxScanDuration;
  final LedgerScanMode scanMode;

  LedgerOptions({
    this.maxScanDuration = 15000,
    this.scanMode = LedgerScanMode.lowPower,
  });
}
