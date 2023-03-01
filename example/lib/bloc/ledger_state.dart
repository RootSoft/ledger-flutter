import 'package:algorand_dart/algorand_dart.dart';
import 'package:equatable/equatable.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

enum LedgerBleStatus {
  idle,
  scanning,
  connected,
  signing,
  failure,
}

class LedgerBleState extends Equatable {
  final LedgerBleStatus status;
  final List<LedgerDevice> devices;
  final List<Address> accounts;
  final LedgerDevice? device;
  final String? signature;
  final dynamic error;

  const LedgerBleState({
    this.status = LedgerBleStatus.idle,
    required this.devices,
    required this.accounts,
    this.device,
    this.signature,
    this.error,
  });

  LedgerBleState copyWith({
    LedgerBleStatus Function()? status,
    List<LedgerDevice> Function()? devices,
    LedgerDevice? Function()? selectedDevice,
    List<Address> Function()? accounts,
    String? Function()? signature,
    dynamic Function()? error,
  }) {
    return LedgerBleState(
      status: status != null ? status() : this.status,
      devices: devices != null ? devices() : this.devices,
      device: selectedDevice != null ? selectedDevice() : device,
      accounts: accounts != null ? accounts() : this.accounts,
      signature: signature != null ? signature() : this.signature,
      error: error != null ? error() : this.error,
    );
  }

  LedgerBleState failure({
    dynamic Function()? error,
  }) {
    return LedgerBleState(
      status: LedgerBleStatus.failure,
      devices: const [],
      device: null,
      accounts: const [],
      signature: null,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        devices,
        device,
        accounts,
        signature,
        error,
      ];
}
