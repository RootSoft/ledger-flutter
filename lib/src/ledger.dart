import 'package:ledger_flutter/ledger.dart';

typedef PermissionRequestCallback = Future<bool> Function(BleStatus status);

class Ledger {
  final BleConnectionManager _bleConnectionManager;
  final PermissionRequestCallback? onPermissionRequest;

  Ledger({
    required LedgerOptions options,
    this.onPermissionRequest,
    BleConnectionManager? bleConnectionManager,
  }) : _bleConnectionManager = bleConnectionManager ??
            LedgerBleConnectionManager(
              options: options,
              onPermissionRequest: onPermissionRequest,
            );

  Stream<LedgerDevice> scan({
    LedgerOptions? options,
  }) =>
      _bleConnectionManager.scan();

  Future<void> connect(
    LedgerDevice device, {
    LedgerOptions? options,
  }) =>
      _bleConnectionManager.connect(device, options: options);

  Future<void> disconnect(LedgerDevice device) =>
      _bleConnectionManager.disconnect(device);

  Future<void> stop() => _bleConnectionManager.stop();

  Future<void> close() => _bleConnectionManager.dispose();

  Future<T> sendRequest<T>(
    LedgerDevice device,
    LedgerOperation<T> operation,
  ) =>
      _bleConnectionManager.sendRequest<T>(device, operation);
}
