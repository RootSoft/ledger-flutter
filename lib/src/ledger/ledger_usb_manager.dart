import "dart:async";

import "package:flutter/services.dart";
import "package:ledger_usb_plus/ledger_usb.dart";
import "package:ledger_usb_plus/usb_device.dart";
import "package:universal_platform/universal_platform.dart";

import "../../ledger_flutter_plus.dart" hide LedgerOperation;
import "../operations/ledger_operations.dart";
import "../utils/ledger_exception_utils.dart";

class LedgerUsbManager extends ConnectionManager {
  bool _disposed = false;

  final _ledgerUsb = LedgerUsb();

  LedgerUsbManager();

  @override
  Future<void> connect(LedgerDevice device) async {
    if (_disposed) throw LedgerManagerDisposedException(connectionType);

    try {
      final usbDevice = UsbDevice.fromIdentifier(device.id);
      await _ledgerUsb.requestPermission(usbDevice);
      await _ledgerUsb.open(usbDevice);
    } on PlatformException catch (ex) {
      throw LedgerExceptionUtils.fromPlatformException(ex, connectionType);
    }
  }

  @override
  Future<void> disconnect(String deviceId) async {
    if (_disposed) throw LedgerManagerDisposedException(connectionType);

    try {
      await _ledgerUsb.close();
    } on PlatformException catch (ex) {
      throw LedgerExceptionUtils.fromPlatformException(ex, connectionType);
    }
  }

  @override
  Future<T> sendRawOperation<T>(
    LedgerDevice device,
    LedgerRawOperation<T> operation,
    LedgerTransformer? transformer,
  ) async {
    if (_disposed) throw LedgerManagerDisposedException(connectionType);

    try {
      final writer = ByteDataWriter();
      final apdus = await operation.write(writer);
      final response = await _ledgerUsb.exchange(apdus);
      final reader = ByteDataReader();
      if (transformer != null) {
        final transformed = await transformer.onTransform(response);
        reader.add(transformed);
      } else {
        reader.add(response.expand((e) => e).toList());
      }

      return await operation.read(reader);
    } on PlatformException catch (ex) {
      throw LedgerExceptionUtils.fromPlatformException(ex, connectionType);
    }
  }

  @override // TODO this may need to be implemented
  Stream<BleConnectionState> deviceStateChanges(String deviceId) {
    if (_disposed) throw LedgerManagerDisposedException(connectionType);

    return const Stream.empty();
  }

  @override
  Future<List<LedgerDevice>> get devices async {
    if (_disposed) throw LedgerManagerDisposedException(connectionType);

    try {
      final ledgerUsbDevices = await _ledgerUsb.listDevices();
      return ledgerUsbDevices //
          .map(LedgerDevice.usb)
          .toList();
    } on PlatformException catch (ex) {
      throw LedgerExceptionUtils.fromPlatformException(ex, connectionType);
    }
  }

  @override
  Future<AvailabilityState> get status async =>
      UniversalPlatform.isIOS ? AvailabilityState.unsupported : AvailabilityState.poweredOn;

  @override
  Stream<AvailabilityState> get statusStateChanges {
    if (_disposed) throw LedgerManagerDisposedException(connectionType);

    return const Stream.empty();
  }

  @override
  final ConnectionType connectionType = ConnectionType.usb;

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _ledgerUsb.close();
    } on PlatformException catch (ex) {
      throw LedgerExceptionUtils.fromPlatformException(ex, connectionType);
    }
  }
}
