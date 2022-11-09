import 'dart:async';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ledger_example/bloc/ledger_event.dart';
import 'package:ledger_example/bloc/ledger_state.dart';
import 'package:ledger_example/channel/ledger_channel.dart';
import 'package:ledger_flutter/ledger.dart';

class LedgerBleBloc extends Bloc<LedgerBleEvent, LedgerBleState> {
  final LedgerChannel channel;
  StreamSubscription? _scanSubscription;

  LedgerBleBloc({
    required this.channel,
  }) : super(
          const LedgerBleState(
            devices: [],
            accounts: [],
          ),
        ) {
    on<LedgerBleScanStarted>(_onScanStarted, transformer: restartable());
    on<LedgerBleConnectRequested>(_onConnectStarted);
    on<LedgerBleSignTransactionRequested>(_onSignTransactionRequested);
    on<LedgerBleDisconnectRequested>(_onDisconnectStarted);
  }

  Future<void> _onScanStarted(LedgerBleScanStarted event, Emitter emit) async {
    emit(state.copyWith(
      status: () => LedgerBleStatus.scanning,
    ));

    await emit.forEach(
      channel.ledger.scan(),
      onData: (data) {
        return state.copyWith(
          status: () => LedgerBleStatus.scanning,
          devices: () => [...state.devices, data],
        );
      },
    );
  }

  Future<void> _onConnectStarted(
    LedgerBleConnectRequested event,
    Emitter emit,
  ) async {
    final device = event.device;
    await channel.ledger.connect(device);

    final accounts = <Address>[];

    try {
      final algorandApp = AlgorandLedgerApp(channel.ledger);
      algorandApp.accountIndex = 1;

      final publicKeys = await algorandApp.getAccounts(device);
      accounts.addAll(
        publicKeys.map((pk) => Address.fromAlgorandAddress(pk)).toList(),
      );

      emit(state.copyWith(
        status: () => LedgerBleStatus.connected,
        selectedDevice: () => device,
        accounts: () => accounts,
      ));
    } catch (ex) {
      await channel.ledger.disconnect(device);

      emit(state.copyWith(
        status: () => LedgerBleStatus.failure,
        selectedDevice: () => device,
        accounts: () => accounts,
        error: () => ex,
      ));
    }
  }

  Future<void> _onSignTransactionRequested(
    LedgerBleSignTransactionRequested event,
    Emitter emit,
  ) async {
    final device = event.device;
    try {
      final algorandApp = AlgorandLedgerApp(channel.ledger);
      algorandApp.accountIndex = 1;
      final signature = await algorandApp.signTransaction(
        device,
        event.transaction.toBytes(),
      );

      final signedTx = SignedTransaction(
        transaction: event.transaction,
        signature: signature,
      );

      final txId = await channel.algorand.sendTransaction(
        signedTx,
        waitForConfirmation: true,
      );

      print(txId);
    } catch (ex) {
      print(ex);
    }
  }

  Future<void> _onDisconnectStarted(
    LedgerBleDisconnectRequested event,
    Emitter emit,
  ) async {
    final device = event.device;
    await channel.ledger.disconnect(device);

    emit(state.copyWith(
      status: () => LedgerBleStatus.idle,
      devices: () => [],
      selectedDevice: () => null,
      accounts: () => [],
    ));
  }

  @override
  Future<void> close() async {
    _scanSubscription?.cancel();
    await channel.ledger.close();
    return super.close();
  }
}
