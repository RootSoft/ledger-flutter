import 'package:ledger_flutter/src/api/ble_request.dart';
import 'package:ledger_flutter/src/ledger.dart';

abstract class BleConnectionManager {
  Stream<LedgerDevice> scan({String? filteredAddress});

  Future<void> connect(LedgerDevice device);

  Future<void> disconnect(LedgerDevice device);

  Future<void> sendRequest(LedgerDevice device, BleRequest request);

  Future<void> stop();

  Future<void> dispose();
}
