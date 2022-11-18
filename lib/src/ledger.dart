import 'package:ledger_flutter/ledger.dart';

typedef PermissionRequestCallback = Future<bool> Function(BleStatus status);

class Ledger {
  final BleSearchManager _bleSearchManager;
  final BleConnectionManager _bleConnectionManager;
  final PermissionRequestCallback? onPermissionRequest;

  Ledger({
    required LedgerOptions options,
    this.onPermissionRequest,
    BleSearchManager? bleSearchManager,
    BleConnectionManager? bleConnectionManager,
  })  : _bleSearchManager = bleSearchManager ??
            LedgerBleSearchManager(
              options: options,
              onPermissionRequest: onPermissionRequest,
            ),
        _bleConnectionManager = bleConnectionManager ??
            LedgerBleConnectionManager(
              options: options,
              onPermissionRequest: onPermissionRequest,
            );

  /// Scan for nearby [LedgerDevice]s.
  ///
  /// The [scanMode] of the [LedgerOptions] allows to choose between different
  /// levels of power efficient and/or low latency scan modes.
  ///
  /// Use the [maxScanDuration] for the maximum amount of time BLE discovery
  /// should run in order to find nearby devices.
  ///
  /// You can override the default [LedgerOptions] with the [options] argument.
  Stream<LedgerDevice> scan({
    LedgerOptions? options,
  }) =>
      _bleSearchManager.scan(options: options);

  /// Connect with a [LedgerDevice].
  ///
  /// You can override the default [LedgerOptions] using the [options] argument.
  ///
  /// Use the [prescanDuration] to determine the amount of time BLE discovery
  /// should run in order to find the device before connecting.
  ///
  /// If [connectionTimeout] parameter is supplied and a connection is not
  /// established before [connectionTimeout] expires, the pending connection
  /// attempt will be cancelled and a [TimeoutException] error will be emitted
  /// into the returned stream.
  Future<void> connect(
    LedgerDevice device, {
    LedgerOptions? options,
  }) =>
      _bleConnectionManager.connect(device, options: options);

  /// Disconnect with the specified [LedgerDevice].
  Future<void> disconnect(LedgerDevice device) =>
      _bleConnectionManager.disconnect(device);

  /// Stop scanning for [LedgerDevice]s.
  ///
  /// Scanning is automatically stopped after [maxScanDuration], defined in
  /// your [LedgerOptions].
  Future<void> stopScanning() => _bleSearchManager.stop();

  /// Close any communication with all connected [LedgerDevice]s and free
  /// all resources.
  Future<void> close() => _bleConnectionManager.dispose();

  /// Send a new [LedgerOperation] to the specified [LedgerDevice].
  ///
  /// Throws a [LedgerException] if unable to complete the request.
  Future<T> sendRequest<T>(
    LedgerDevice device,
    LedgerOperation<T> operation,
  ) =>
      _bleConnectionManager.sendRequest<T>(device, operation);

  /// Returns the current status of the BLE subsystem of the host device.
  BleStatus get status => _bleConnectionManager.status;

  /// A stream providing the host device BLE subsystem status updates.
  Stream<BleStatus> get statusStateChanges =>
      _bleConnectionManager.statusStateChanges;

  /// Get a list of connected [LedgerDevice]s.
  List<LedgerDevice> get devices => _bleConnectionManager.devices;

  /// A stream providing connection updates for all the connected BLE devices.
  Stream<ConnectionStateUpdate> get deviceStateChanges =>
      _bleConnectionManager.deviceStateChanges;
}
