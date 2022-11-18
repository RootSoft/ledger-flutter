import 'package:ledger_flutter/ledger.dart';

abstract class BleConnectionManager {
  Future<void> connect(LedgerDevice device, {LedgerOptions? options});

  Future<void> disconnect(LedgerDevice device);

  Future<T> sendRequest<T>(LedgerDevice device, LedgerOperation request);

  Future<void> dispose();

  /// Returns the current status of the BLE subsystem of the host device.
  BleStatus get status;

  /// A stream providing connection updates for all the connected BLE devices.
  Stream<ConnectionStateUpdate> get deviceStateChanges;

  /// Get a list of connected [LedgerDevice]s.
  List<LedgerDevice> get devices;
}
