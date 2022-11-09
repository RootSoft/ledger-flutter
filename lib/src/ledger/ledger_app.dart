import 'dart:typed_data';

import 'package:ledger_flutter/ledger.dart';

abstract class LedgerApp {
  final Ledger ledger;

  LedgerApp(this.ledger);

  Future<List<String>> getAccounts(LedgerDevice device);

  Future<Uint8List> signTransaction(
    LedgerDevice device,
    Uint8List transaction,
  );

  Future<List<Uint8List>> signTransactions(
    LedgerDevice device,
    List<Uint8List> transactions,
  );
}
