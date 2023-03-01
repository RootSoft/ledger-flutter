import 'package:ledger_flutter/ledger_flutter.dart';

abstract class BleSearchManager {
  Stream<LedgerDevice> scan({LedgerOptions? options});

  Future<void> stop();

  Future<void> dispose();
}
