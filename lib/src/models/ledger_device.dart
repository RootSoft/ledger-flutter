import 'package:ledger_flutter/src/ledger/connection_type.dart';
import 'package:ledger_usb/usb_device.dart';

class LedgerDevice {
  final String id;
  final String name;
  final ConnectionType connectionType;
  final int rssi;

  LedgerDevice({
    required this.id,
    required this.name,
    required this.connectionType,
    this.rssi = 0,
  });

  factory LedgerDevice.fromUsbDevice(UsbDevice device) {
    return LedgerDevice(
      id: device.identifier,
      name: device.productName,
      connectionType: ConnectionType.usb,
    );
  }

  LedgerDevice copyWith({
    String Function()? id,
    String Function()? name,
    ConnectionType Function()? connectionType,
    int Function()? rssi,
  }) {
    return LedgerDevice(
      id: id != null ? id() : this.id,
      name: name != null ? name() : this.name,
      connectionType:
          connectionType != null ? connectionType() : this.connectionType,
      rssi: rssi != null ? rssi() : this.rssi,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
