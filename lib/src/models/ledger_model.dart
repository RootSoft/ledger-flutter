import 'package:ledger_flutter/src/algorand/public_key_ble_request.dart';
import 'package:ledger_flutter/src/ledger.dart';
import 'package:ledger_flutter/src/ledger/ledger_ble_connection_manager.dart';

typedef PermissionRequestCallback = Future<bool> Function();

class Ledger {
  final LedgerOptions _options;
  final BleConnectionManager _bleConnectionManager;
  final PermissionRequestCallback? onPermissionRequest;

  Ledger({
    required LedgerOptions options,
    this.onPermissionRequest,
    BleConnectionManager? bleConnectionManager,
  })  : _options = options,
        _bleConnectionManager = bleConnectionManager ??
            LedgerBleConnectionManager(
              options: options,
              onPermissionRequest: onPermissionRequest,
            );

  Stream<LedgerDevice> scan({String? filteredAddress}) =>
      _bleConnectionManager.scan(
        filteredAddress: filteredAddress,
        //onDeviceFound: (device) {},
      );

  Future<void> connect(LedgerDevice device) =>
      _bleConnectionManager.connect(device);

  Future<void> disconnect(LedgerDevice device) =>
      _bleConnectionManager.disconnect(device);

  Future<void> stop() => _bleConnectionManager.stop();

  Future<void> dispose() => _bleConnectionManager.dispose();

  Future<void> getAddresses(LedgerDevice device) =>
      _bleConnectionManager.sendRequest(device, PublicKeyBleRequest());
}
