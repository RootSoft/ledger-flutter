import 'package:flutter/material.dart';
import 'package:ledger_flutter/ledger_flutter.dart';

typedef LedgerGestureCallback = void Function(LedgerDevice ledger);

class LedgerListTile extends StatelessWidget {
  final LedgerDevice ledger;
  final LedgerGestureCallback? onTap;

  const LedgerListTile({
    required this.ledger,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(ledger.name),
      onTap: () {
        onTap?.call(ledger);
      },
    );
  }
}
