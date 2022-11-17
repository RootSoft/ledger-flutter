import 'package:ledger_flutter/ledger.dart';

abstract class BleConnectionManager {
  Future<void> connect(LedgerDevice device, {LedgerOptions? options});

  Future<void> disconnect(LedgerDevice device);

  Future<T> sendRequest<T>(LedgerDevice device, LedgerOperation request);

  Future<void> dispose();
}
