import 'package:algorand_dart/algorand_dart.dart';
import 'package:equatable/equatable.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

enum LedgerBleStatus {
  idle,
  scanning,
  connected,
  signing,
}

class LedgerBleState extends Equatable {
  final LedgerBleStatus status;
  final List<LedgerDevice> devices;
  final List<Address> accounts;
  final LedgerDevice? device;

  const LedgerBleState({
    this.status = LedgerBleStatus.idle,
    required this.devices,
    required this.accounts,
    this.device,
  });

  LedgerBleState copyWith({
    LedgerBleStatus Function()? status,
    List<LedgerDevice> Function()? devices,
    LedgerDevice? Function()? selectedDevice,
    List<Address> Function()? accounts,
  }) {
    return LedgerBleState(
      status: status != null ? status() : this.status,
      devices: devices != null ? devices() : this.devices,
      device: selectedDevice != null ? selectedDevice() : device,
      accounts: accounts != null ? accounts() : this.accounts,
    );
  }

  @override
  List<Object?> get props => [status, devices, device, accounts];
}
