import 'package:equatable/equatable.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

enum LedgerBleStatus {
  idle,
  devicesFound,
  connected,
  signing,
}

class LedgerBleState extends Equatable {
  final LedgerBleStatus status;
  final List<LedgerDevice> devices;
  final LedgerDevice? device;

  const LedgerBleState({
    this.status = LedgerBleStatus.idle,
    required this.devices,
    this.device,
  });

  LedgerBleState copyWith({
    LedgerBleStatus Function()? status,
    List<LedgerDevice> Function()? devices,
    LedgerDevice? Function()? selectedDevice,
  }) {
    return LedgerBleState(
      status: status != null ? status() : this.status,
      devices: devices != null ? devices() : this.devices,
      device: selectedDevice != null ? selectedDevice() : device,
    );
  }

  @override
  List<Object?> get props => [status, devices, device];
}
