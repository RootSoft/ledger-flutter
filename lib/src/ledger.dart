import 'package:ledger_flutter/ledger.dart';

typedef PermissionRequestCallback = Future<bool> Function(BleStatus status);

class Ledger {
  final UsbManager _usbManager;
  final BleSearchManager _bleSearchManager;
  final BleConnectionManager _bleConnectionManager;
  final PermissionRequestCallback? onPermissionRequest;

  Ledger({
    required LedgerOptions options,
    this.onPermissionRequest,
    UsbManager? usbManager,
    BleSearchManager? bleSearchManager,
    BleConnectionManager? bleConnectionManager,
  })  : _usbManager = usbManager ?? LedgerUsbManager(),
        _bleSearchManager = bleSearchManager ??
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

  /// List all connected Ledger USB devices.
  Future<List<LedgerDevice>> listUsbDevices() => _usbManager.listDevices();

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
  }) {
    switch (device.connectionType) {
      case ConnectionType.usb:
        return _usbManager.connect(device, options: options);
      case ConnectionType.ble:
        return _bleConnectionManager.connect(device, options: options);
    }
  }

  /// Disconnect with the specified [LedgerDevice].
  Future<void> disconnect(LedgerDevice device) {
    switch (device.connectionType) {
      case ConnectionType.usb:
        return _usbManager.disconnect(device);
      case ConnectionType.ble:
        return _bleConnectionManager.disconnect(device);
    }
  }

  /// Stop scanning for BLE [LedgerDevice]s.
  ///
  /// Scanning is automatically stopped after [maxScanDuration], defined in
  /// your [LedgerOptions].
  Future<void> stopScanning() => _bleSearchManager.stop();

  /// Close any communication with all connected [LedgerDevice]s and free
  /// all resources.
  Future<void> close() async {
    await _usbManager.dispose();
    await _bleConnectionManager.dispose();
  }

  /// Send a new [LedgerOperation] to the specified [LedgerDevice].
  ///
  /// Throws a [LedgerException] if unable to complete the request.
  Future<T> sendOperation<T>(
    LedgerDevice device,
    LedgerOperation<T> operation, {
    LedgerTransformer? transformer,
  }) {
    switch (device.connectionType) {
      case ConnectionType.usb:
        return _usbManager.sendOperation<T>(device, operation, transformer);
      case ConnectionType.ble:
        return _bleConnectionManager.sendOperation<T>(
          device,
          operation,
          transformer,
        );
    }
  }

  /// Returns the current status of the BLE subsystem of the host device.
  BleStatus get status => _bleConnectionManager.status;

  /// A stream providing the host device BLE subsystem status updates.
  Stream<BleStatus> get statusStateChanges =>
      _bleConnectionManager.statusStateChanges;

  /// Get a list of connected BLE [LedgerDevice]s.
  List<LedgerDevice> get devices => _bleConnectionManager.devices;

  /// A stream providing connection updates for all the connected BLE devices.
  Stream<ConnectionStateUpdate> get deviceStateChanges =>
      _bleConnectionManager.deviceStateChanges;
}
