import 'package:ledger_flutter/ledger.dart';

abstract class LedgerOperation {
  LedgerDevice get device;
  int nextIndex = 0;
}
