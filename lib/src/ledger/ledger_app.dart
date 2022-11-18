import 'dart:typed_data';

import 'package:ledger_flutter/ledger.dart';

/// Applications on Ledger devices play a vital role in managing your crypto
/// assets – for each cryptocurrency, there’s a dedicated app.
/// These apps can be installed onto your hardware wallet by connecting it to
/// Ledger Live.
abstract class LedgerApp {
  final Ledger ledger;

  LedgerApp(this.ledger);

  Future<dynamic> getVersion(LedgerDevice device);

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
