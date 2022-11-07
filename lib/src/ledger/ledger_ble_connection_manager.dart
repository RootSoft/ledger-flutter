import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:ledger_flutter/src/api/ble_request.dart';
import 'package:ledger_flutter/src/api/gatt_gateway.dart';
import 'package:ledger_flutter/src/exceptions/ledger_exception.dart';
import 'package:ledger_flutter/src/ledger/ledger_gatt_gateway.dart';
import 'package:ledger_flutter/src/models/discovered_ledger.dart';

class LedgerBleConnectionManager extends BleConnectionManager {
  /// Ledger Nano X service id
  static const serviceId = '13D63400-2C97-0004-0000-4C6564676572';
  static const writeCharacteristicKey = '13D63400-2C97-0004-0002-4C6564676572';
  static const notifyCharacteristicKey = '13D63400-2C97-0004-0001-4C6564676572';

  final bleManager = FlutterReactiveBle();
  final LedgerOptions options;
  final PermissionRequestCallback? onPermissionRequest;
  final _scannedIds = <String>{};
  final _connectedDevices = <String, GattGateway>{};

  bool _isScanning = false;
  StreamSubscription? _scanSubscription;
  StreamController<LedgerDevice> streamController =
      StreamController.broadcast();

  LedgerBleConnectionManager({
    required this.options,
    this.onPermissionRequest,
  });

  @override
  Stream<LedgerDevice> scan({String? filteredAddress}) async* {
    if (_isScanning) {
      return;
    }

    // Check for permissions
    final onPermissionGranted = (await onPermissionRequest?.call()) ?? true;
    if (!onPermissionGranted) {
      print('Permission not granted!');
      return;
    }

    // Start scanning
    _isScanning = true;
    _scannedIds.clear();

    _scanSubscription?.cancel();
    _scanSubscription = bleManager.scanForDevices(
      withServices: [Uuid.parse(serviceId)],
      scanMode: ScanMode.lowLatency,
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

    Future.delayed(Duration(milliseconds: options.maxScanDuration), () {
      stop();
    });

    yield* streamController.stream;
  }

  @override
  Future<void> connect(
    LedgerDevice device,
  ) async {
    // Stop scanning when connecting to a device.
    await stop();

    // There are numerous issues on the Android BLE stack that leave it hanging
    // when you try to connect to a device that is not in range.
    // To work around this issue use the method connectToAdvertisingDevice to
    // first scan for the device and only if it is found connect to it.
    final c = Completer();

    StreamSubscription? subscription;

    _connectedDevices[device.id]?.disconnect();
    subscription = bleManager
        .connectToAdvertisingDevice(
      id: device.id,
      withServices: [Uuid.parse(serviceId)],
      prescanDuration: const Duration(seconds: 5),
      connectionTimeout: const Duration(seconds: 2),
    )
        .listen(
      (state) async {
        if (state.connectionState == DeviceConnectionState.connected) {
          final services = await bleManager.discoverServices(device.id);
          final ledger = DiscoveredLedger(
            device: device,
            subscription: subscription,
            services: services,
          );

          final gateway = LedgerGattGateway(
            bleManager: bleManager,
            ledger: ledger,
          );

          await gateway.start();
          _connectedDevices[device.id] = gateway;

          c.complete();
        }

        print(state);
      },
      onError: (ex) {
        c.completeError(ex);
      },
    );

    return c.future;
  }

  @override
  Future<T> sendRequest<T>(LedgerDevice device, BleRequest request) async {
    final d = _connectedDevices[device.id];
    if (d == null) {
      throw LedgerException();
    }

    return d.sendRequest<T>(request);
  }

  @override
  Future<void> disconnect(LedgerDevice device) async {
    _connectedDevices[device.id]?.disconnect();
    _connectedDevices.remove(device.id);
  }

  @override
  Future<void> stop() async {
    _isScanning = false;
    _scanSubscription?.cancel();
  }

  @override
  Future<void> dispose() async {
    await stop();

    for (var subscription in _connectedDevices.values) {
      subscription.disconnect();
    }

    _connectedDevices.clear();
  }
}
