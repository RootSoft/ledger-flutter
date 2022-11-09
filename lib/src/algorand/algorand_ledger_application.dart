import 'dart:typed_data';

import 'package:ledger_flutter/ledger.dart';
import 'package:ledger_flutter/src/algorand/algorand_public_key_operation.dart';
import 'package:ledger_flutter/src/algorand/algorand_sign_msgpack_transaction.dart';

/// A [LedgerApp] used to perform BLE operations on a ledger [Algorand]
/// application.
class AlgorandLedgerApp extends LedgerApp {
  int accountIndex;

  AlgorandLedgerApp(
    super.ledger, {
    this.accountIndex = 0,
  });

  @override
  Future<List<String>> getAccounts(LedgerDevice device) async {
    return ledger.sendRequest<List<String>>(
      device,
      AlgorandPublicKeyOperation(accountIndex: accountIndex),
    );
  }

  @override
  Future<Uint8List> signTransaction(
    LedgerDevice device,
    Uint8List transaction,
  ) {
    return ledger.sendRequest<Uint8List>(
      device,
      AlgorandSignMsgPackTransaction(
        accountIndex: accountIndex,
        transaction: transaction,
      ),
    );
  }

  @override
  Future<List<Uint8List>> signTransactions(
    LedgerDevice device,
    List<Uint8List> transactions,
  ) async {
    // Future.wait(transactions.map((tx) => signTransaction(device, tx)))
    final signatures = <Uint8List>[];
    for (var tx in transactions) {
      final signature = await signTransaction(device, tx);
      signatures.add(signature);
    }

    return signatures;
  }
}
