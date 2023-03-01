import 'package:ledger_flutter/ledger_flutter.dart';

abstract class UsbManager {
  Future<List<LedgerDevice>> listDevices();

  Future<void> connect(LedgerDevice device, {LedgerOptions? options});

  Future<void> disconnect(LedgerDevice device);

  Future<T> sendOperation<T>(
    LedgerDevice device,
    LedgerOperation<T> operation,
    LedgerTransformer? transformer,
  );

  Future<void> dispose();
}
