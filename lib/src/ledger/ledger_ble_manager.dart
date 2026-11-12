import "dart:async";

import "package:flutter/foundation.dart";
import "package:universal_ble/universal_ble.dart";

import "../api/connection_manager.dart";
import "../exceptions/ledger_exception.dart";
import "../ledger_interface.dart";
import "../models/connection_change_event.dart";
import "../models/discovered_ledger.dart";
import "../models/ledger_device.dart";
import "../operations/ledger_operations.dart";
import "connection_type.dart";
import "ledger_device_type.dart";
import "ledger_gatt_gateway.dart";
import "ledger_transformer.dart";

const _bleMasterTimeout = Duration(seconds: 60);
const _bleConnectionTimeout = Duration(seconds: 30);
const _bleCheckConnectionTimeout = Duration(seconds: 5);

class LedgerBleConnectionManager extends ConnectionManager {
  bool _disposed = false;

  final PermissionRequestCallback onPermissionRequest;

  final _connectedDevices = <String, ({LedgerGattGateway gateway, LedgerDevice device})>{};
  final _connectionStateControllers = <String, StreamController<BleConnectionState>>{};

  final List<OnConnectionChange> _connectionChangeListeners = [];

  final _onConnectionChangeController = StreamController<BleConnectionChangeEvent>();
  final _statusStateChangesController = StreamController<AvailabilityState>();

  LedgerBleConnectionManager({
    required this.onPermissionRequest,
  }) {
    _connectionChangeListeners.add(_handleConnectionChange);
    UniversalBle.onConnectionChange = (change) {
      final state = change.isConnected ? BleConnectionState.connected : BleConnectionState.disconnected;

      _onConnectionChangeController.add(
        BleConnectionChangeEvent(
          deviceId: change.deviceId,
          newState: state,
        ),
      );

      // Copy the list because we get a ConcurrentModificationError otherwise
      final List<OnConnectionChange> connectionChangeListeners = [
        ..._connectionChangeListeners,
      ];

      for (final OnConnectionChange listener in connectionChangeListeners) {
        try {
          listener(change);
        } catch (e) {
          debugPrint("Error in connection change listener: $e");
        }
      }
    };
  }

  @override
  Future<void> connect(LedgerDevice device) async {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    final availabilityState = await UniversalBle.getBluetoothAvailabilityState();
    final granted = await onPermissionRequest(availabilityState);
    if (!granted) {
      return;
    }

    UniversalBle.timeout = _bleMasterTimeout;

    try {
      try {
        final connectionState = await UniversalBle.getConnectionState(
          device.id,
        ).timeout(
          _bleCheckConnectionTimeout,
          onTimeout: () => BleConnectionState.disconnected,
        );
        switch (connectionState) {
          case BleConnectionState.connected:
          case BleConnectionState.connecting:
            break;
          case BleConnectionState.disconnected:
          case BleConnectionState.disconnecting:
            await UniversalBle.connect(device.id);
        }
      } catch (e) {
        disconnect(device.id).ignore();
        throw EstablishConnectionException(
          connectionType: ConnectionType.ble,
          nestedError: e,
        );
      }

      final services = await UniversalBle.discoverServices(device.id).timeout(
        _bleConnectionTimeout,
        onTimeout: () => throw TimeoutException(
          "UniversalBle.discoverServices",
          _bleConnectionTimeout,
        ),
      );

      // The scan cannot tell the device type on web (no advertised services), so take it from the discovered services.
      // Without this a Flex, Stax or Nano Gen5 found on web is treated as a Nano X and its service is never found.
      final deviceType = LedgerDeviceType.fromBleServices(services.map((e) => e.uuid));
      final connectedDevice = deviceType == null ? device : device.copyWith(deviceInfo: () => deviceType);

      final subscription = _getOrCreateConnectionStateController(_canonicalId(device.id));

      final ledger = DiscoveredLedger(
        device: connectedDevice,
        services: services,
        subscription: subscription.stream.listen((state) {}),
      );

      final gateway = LedgerGattGateway(ledger: ledger);

      await gateway.start().timeout(
            _bleMasterTimeout,
            onTimeout: () => throw TimeoutException(
              "gateway.start",
              _bleMasterTimeout,
            ),
          );
      _connectedDevices[_canonicalId(device.id)] = (gateway: gateway, device: connectedDevice);
    } on LedgerException {
      await disconnect(device.id);
      rethrow;
    }
  }

  void _handleConnectionChange(BleConnectionChange change) {
    final state = change.isConnected ? BleConnectionState.connected : BleConnectionState.disconnected;
    // The link is gone: drop the session so requests waiting on it fail instead of hanging.
    if (!change.isConnected) _connectedDevices.remove(change.deviceId)?.gateway.connectionLost();
    _getOrCreateConnectionStateController(change.deviceId).add(state);
  }

  StreamController<BleConnectionState> _getOrCreateConnectionStateController(
    String deviceId,
  ) =>
      _connectionStateControllers.putIfAbsent(
        deviceId,
        StreamController<BleConnectionState>.broadcast,
      );

  @override
  Future<T> sendRawOperation<T>(
    LedgerDevice device,
    LedgerRawOperation<T> operation,
    LedgerTransformer? transformer,
  ) async {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    final d = _connectedDevices[_canonicalId(device.id)];
    if (d == null) {
      throw DeviceNotConnectedException(
        requestedOperation: "ble_manager: sendOperation",
        connectionType: ConnectionType.ble,
      );
    }

    return d.gateway.sendOperation<T>(
      operation,
      transformer: transformer,
    );
  }

  @override
  Future<AvailabilityState> get status {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    return UniversalBle.getBluetoothAvailabilityState();
  }

  @override
  Stream<AvailabilityState> get statusStateChanges {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    UniversalBle.onAvailabilityChange = _statusStateChangesController.add;
    return _statusStateChangesController.stream;
  }

  @override
  Future<List<LedgerDevice>> get devices async {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    return _connectedDevices.values.map((e) => e.device).toList();
  }

  @override
  Stream<BleConnectionState> deviceStateChanges(String deviceId) {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    final id = _canonicalId(deviceId);
    return _onConnectionChangeController.stream.where((e) => e.deviceId == id).map((e) => e.newState);
  }

  @override
  Future<void> disconnect(String deviceId) async {
    if (_disposed) throw LedgerManagerDisposedException(ConnectionType.ble);

    await _disconnect(deviceId);
  }

  // Bypass dispose check here because this method is called from dispose
  Future<void> _disconnect(String deviceId) async {
    final id = _canonicalId(deviceId);
    final gateway = _connectedDevices.remove(id)?.gateway;
    if (gateway != null) {
      // UniversalBle.disconnect is called internally by gateway.disconnect
      await gateway.disconnect();
    } else {
      await UniversalBle.disconnect(deviceId);
    }

    unawaited(_connectionStateControllers.remove(id)?.close());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    unawaited(_onConnectionChangeController.close());
    unawaited(_statusStateChangesController.close());

    final deviceIds = List<String>.from(_connectedDevices.keys);
    for (final deviceId in deviceIds) {
      try {
        await _disconnect(deviceId);
      } catch (e) {
        // ignore
      }
    }
    _connectedDevices.clear();
    for (final controller in _connectionStateControllers.values) {
      try {
        await controller.close();
      } catch (e) {
        // ignore
      }
    }
    _connectionStateControllers.clear();
    UniversalBle.onConnectionChange = null;
    UniversalBle.onAvailabilityChange = null;
  }

  @override
  final ConnectionType connectionType = ConnectionType.ble;
}

/// universal_ble emits device ids in canonical form (lower-case on native platforms, verbatim on web), so ids passed in
/// by callers, e.g. an upper-case Android MAC kept from an older version, are canonicalised before comparing or keying.
String _canonicalId(String deviceId) => UniversalBle.canonicalDeviceId(deviceId);
