import 'package:equatable/equatable.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

abstract class LedgerBleEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LedgerBleScanStarted extends LedgerBleEvent {}

class LedgerBleConnectRequested extends LedgerBleEvent {
  final LedgerDevice device;

  LedgerBleConnectRequested(this.device);

  @override
  List<Object?> get props => [device];
}

class LedgerBleDisconnectRequested extends LedgerBleEvent {
  final LedgerDevice device;

  LedgerBleDisconnectRequested(this.device);

  @override
  List<Object?> get props => [device];
}
