import 'dart:async';

import 'package:ledger_flutter/ledger.dart';

class LedgerBleConnectionManager extends BleConnectionManager {
  /// Ledger Nano X service id
  static const serviceId = '13D63400-2C97-0004-0000-4C6564676572';

  final _bleManager = FlutterReactiveBle();
  final LedgerOptions _options;
  final PermissionRequestCallback? onPermissionRequest;
  final _connectedDevices = <String, GattGateway>{};

  LedgerBleConnectionManager({
    required LedgerOptions options,
    this.onPermissionRequest,
  }) : _options = options;

  @override
  Future<void> connect(
    LedgerDevice device, {
    LedgerOptions? options,
  }) async {
    // Check for permissions
    final granted = (await onPermissionRequest?.call(status)) ?? true;
    if (!granted) {
      return;
    }

    // There are numerous issues on the Android BLE stack that leave it hanging
    // when you try to connect to a device that is not in range.
    // To work around this issue use the method connectToAdvertisingDevice to
    // first scan for the device and only if it is found connect to it.
    final c = Completer();

    StreamSubscription? subscription;
    _connectedDevices[device.id]?.disconnect();

    subscription = _bleManager
        .connectToAdvertisingDevice(
      id: device.id,
      withServices: [Uuid.parse(serviceId)],
      prescanDuration: options?.prescanDuration ?? _options.prescanDuration,
      connectionTimeout:
          options?.connectionTimeout ?? _options.connectionTimeout,
    )
        .listen(
      (state) async {
        if (state.connectionState == DeviceConnectionState.connected) {
          final services = await _bleManager.discoverServices(device.id);
          final ledger = DiscoveredLedger(
            device: device,
            subscription: subscription,
            services: services,
          );

          final gateway = LedgerGattGateway(
            bleManager: _bleManager,
            ledger: ledger,
            mtu: options?.mtu ?? _options.mtu,
            onError: (ex) async {
              await disconnect(device);
            },
          );

          await gateway.start();
          _connectedDevices[device.id] = gateway;

          c.complete();
        }

        if (state.connectionState == DeviceConnectionState.disconnected) {
          await disconnect(device);
        }
      },
      onError: (ex) async {
        await disconnect(device);
        c.completeError(ex);
      },
    );

    return c.future;
  }

  @override
  Future<T> sendRequest<T>(
    LedgerDevice device,
    LedgerOperation request,
  ) async {
    final d = _connectedDevices[device.id];
    if (d == null) {
      throw LedgerException(message: 'Unable to send request.');
    }

    return d.sendRequest<T>(request);
  }

  /// Returns the current status of the BLE subsystem of the host device.
  BleStatus get status => _bleManager.status;

  @override
  Future<void> disconnect(LedgerDevice device) async {
    _connectedDevices[device.id]?.disconnect();
    _connectedDevices.remove(device.id);
  }

  @override
  Future<void> dispose() async {
    for (var subscription in _connectedDevices.values) {
      subscription.disconnect();
    }

    _connectedDevices.clear();
  }
}
