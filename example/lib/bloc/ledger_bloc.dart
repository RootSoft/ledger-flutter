import 'dart:async';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ledger_algorand/ledger_algorand.dart';
import 'package:ledger_example/bloc/ledger_event.dart';
import 'package:ledger_example/bloc/ledger_state.dart';
import 'package:ledger_example/channel/ledger_channel.dart';

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
    on<LedgerBleUsbStarted>(_onUsbStarted);
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

  Future<void> _onUsbStarted(LedgerBleUsbStarted event, Emitter emit) async {
    final devices = await channel.ledger.listUsbDevices();
    final currentState = state;

    emit(currentState.copyWith(
      status: () => LedgerBleStatus.scanning,
      devices: () => [...state.devices, ...devices],
    ));
  }

  Future<void> _onConnectStarted(
    LedgerBleConnectRequested event,
    Emitter emit,
  ) async {
    final device = event.device;
    await channel.ledger.stopScanning();
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
    final account = event.account;
    final tx = await _buildTransaction(account: account);

    try {
      final algorandApp = AlgorandLedgerApp(channel.ledger);
      algorandApp.accountIndex = 1;
      final signature = await algorandApp.signTransaction(
        device,
        tx.toBytes(),
      );

      final signedTx = SignedTransaction(
        transaction: tx,
        signature: signature,
      );

      final txId = await channel.algorand.sendTransaction(
        signedTx,
        waitForConfirmation: true,
      );

      if (kDebugMode) {
        print(txId);
        print(signedTx);
      }

      emit(state.copyWith(
        signature: () => hex.encode(signature),
      ));
    } catch (ex) {
      if (kDebugMode) {
        print(ex);
      }
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
      signature: () => null,
    ));
  }

  @override
  Future<void> close() async {
    _scanSubscription?.cancel();
    final device = state.device;
    if (device != null) {
      await channel.ledger.dispose(
        onError: (error) {},
      );
    }

    return super.close();
  }

  Future<RawTransaction> _buildTransaction({required Address account}) async {
    final tx = await channel.algorand.createPaymentTransaction(
      sender: account,
      receiver: account,
      amount: Algo.toMicroAlgos(1),
    );

    return tx;
  }

  Future<RawTransaction> _buildTransaction2({required Address account}) async {
    final params = (await channel.algorand.getSuggestedTransactionParams());
    int inputAssetIndicator = 0x04;
    final part1 = Uint8List.fromList([inputAssetIndicator]);
    final part2 = convertTo64BitBigEndian(100000);
    final part3 = convertTo64BitBigEndian(23035);
    final part4 = Uint8List(73);
    final txn2Arguments = <Uint8List>[
      Uint8List.fromList([0x00]),
      Uint8List.fromList([0x03]),
      convertTo64BitBigEndian(0),
      Uint8List.fromList(part1 + part2 + part3 + part4),
    ];
    // Create the transaction
    final tx = await (ApplicationBaseTransactionBuilder()
          ..sender = Address.fromAlgorandAddress(account.encodedAddress)
          ..flatFee = 3000
          ..applicationId = 777628254
          ..foreignAssets = [31566704]
          ..arguments = txn2Arguments
          ..suggestedParams = params)
        .build();
    AtomicTransfer.group([tx]);
    return tx;
  }

  static Uint8List convertTo64BitBigEndian(int number) {
    final result = Uint8List(8);
    for (int i = 0; i < 8; ++i) {
      result[i] = (number >> (8 * (7 - i))) & 0xFF;
    }
    return result;
  }
}
