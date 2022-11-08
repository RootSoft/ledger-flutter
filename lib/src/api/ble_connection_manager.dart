import 'package:ledger_flutter/src/ledger.dart';
import 'package:ledger_flutter/src/ledger/ledger_operation.dart';

abstract class BleConnectionManager {
  Stream<LedgerDevice> scan({LedgerOptions? options});

  Future<void> connect(LedgerDevice device, {LedgerOptions? options});

  Future<void> disconnect(LedgerDevice device);

  Future<T> sendRequest<T>(LedgerDevice device, LedgerOperation request);

  Future<void> stop();

  Future<void> dispose();
}
