import 'package:algorand_dart/algorand_dart.dart';
import 'package:equatable/equatable.dart';
import 'package:ledger_flutter/ledger.dart';

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

class LedgerBleSignTransactionRequested extends LedgerBleEvent {
  final LedgerDevice device;
  final RawTransaction transaction;

  LedgerBleSignTransactionRequested(this.device, this.transaction);

  @override
  List<Object?> get props => [device, transaction];
}
