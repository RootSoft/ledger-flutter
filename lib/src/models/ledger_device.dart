import "package:flutter/foundation.dart";
import "package:ledger_usb_plus/usb_device.dart";

import "../ledger/connection_type.dart";
import "../ledger/ledger_device_type.dart";

@immutable
class LedgerDevice {
  final String id;
  final String name;
  final ConnectionType connectionType;
  final int rssi;
  final LedgerDeviceType deviceInfo;

  const LedgerDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    required this.deviceInfo,
    this.rssi = 0,
  });

  factory LedgerDevice.ble({
    required String id,
    required String name,
    required LedgerDeviceType deviceInfo,
    int rssi = 0,
  }) =>
      LedgerDevice(
        id: id,
        name: name,
        connectionType: ConnectionType.ble,
        rssi: rssi,
        deviceInfo: deviceInfo,
      );

  factory LedgerDevice.usb(UsbDevice device) => LedgerDevice(
        id: device.identifier,
        name: device.productName,
        connectionType: ConnectionType.usb,
        deviceInfo: LedgerDeviceType.values.firstWhere(
          (e) => device.productId >> 8 == e.productIdMM,
          orElse: () => LedgerDeviceType.nanoX,
        ),
      );

  LedgerDevice copyWith({
    String Function()? id,
    String Function()? name,
    ConnectionType Function()? connectionType,
    int Function()? rssi,
    LedgerDeviceType Function()? deviceInfo,
  }) {
    return LedgerDevice(
      id: id != null ? id() : this.id,
      name: name != null ? name() : this.name,
      connectionType: connectionType != null ? connectionType() : this.connectionType,
      rssi: rssi != null ? rssi() : this.rssi,
      deviceInfo: deviceInfo != null ? deviceInfo() : this.deviceInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LedgerDevice && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
