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
      title: Text('${ledger.name} ($connectionType)'),
      onTap: () {
        onTap?.call(ledger);
      },
    );
  }

  String get connectionType {
    switch (ledger.connectionType) {
      case ConnectionType.usb:
        return 'USB';
      case ConnectionType.ble:
        return 'BLE';
    }
  }
}
