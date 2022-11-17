import 'dart:async';

import 'package:ledger_flutter/ledger.dart';

class LedgerBleSearchManager extends BleSearchManager {
  /// Ledger Nano X service id
  static const serviceId = '13D63400-2C97-0004-0000-4C6564676572';
  static const writeCharacteristicKey = '13D63400-2C97-0004-0002-4C6564676572';
  static const notifyCharacteristicKey = '13D63400-2C97-0004-0001-4C6564676572';

  final bleManager = FlutterReactiveBle();
  final LedgerOptions _options;
  final PermissionRequestCallback? onPermissionRequest;

  final _scannedIds = <String>{};
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;
  StreamController<LedgerDevice> streamController =
      StreamController.broadcast();

  LedgerBleSearchManager({
    required LedgerOptions options,
    this.onPermissionRequest,
  }) : _options = options;

  @override
  Stream<LedgerDevice> scan({LedgerOptions? options}) async* {
    // Check for permissions
    final granted = (await onPermissionRequest?.call(status)) ?? true;
    if (!granted) {
      return;
    }

    if (_isScanning) {
      return;
    }

    // Start scanning
    _isScanning = true;
    _scannedIds.clear();

    _scanSubscription?.cancel();
    _scanSubscription = bleManager.scanForDevices(
      withServices: [Uuid.parse(serviceId)],
      scanMode: options?.scanMode ?? _options.scanMode,
      requireLocationServicesEnabled: options?.requireLocationServicesEnabled ??
          _options.requireLocationServicesEnabled,
    ).listen(
      (device) {
        if (_scannedIds.contains(device.id)) {
          return;
        }

        final lDevice = LedgerDevice(
          id: device.id,
          address: device.id,
          name: device.name,
          rssi: device.rssi,
        );

        _scannedIds.add(lDevice.id);
        streamController.add(lDevice);
      },
    );

    Future.delayed(options?.maxScanDuration ?? _options.maxScanDuration, () {
      stop();
    });

    yield* streamController.stream;
  }

  @override
  Future<void> stop() async {
    if (!_isScanning) {
      return;
    }

    _isScanning = false;
    _scanSubscription?.cancel();
  }

  @override
  Future<void> dispose() async {
    await stop();
  }

  /// Returns the current status of the BLE subsystem of the host device.
  BleStatus get status => bleManager.status;
}
