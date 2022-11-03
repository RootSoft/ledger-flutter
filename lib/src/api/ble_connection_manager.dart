import 'package:ledger_flutter/src/ledger.dart';

abstract class BleConnectionManager {
  Stream<LedgerDevice> scan({String? filteredAddress});

  Future<void> connect(LedgerDevice device);

  Future<void> disconnect(LedgerDevice device);

  Future<void> stop();

  Future<void> dispose();
}
