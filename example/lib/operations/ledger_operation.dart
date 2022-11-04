import 'package:ledger_flutter/ledger_flutter.dart';

abstract class LedgerOperation {
  LedgerDevice get device;
  int nextIndex = 0;
}
