import 'package:ledger_flutter/ledger_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LedgerChannel {
  final Ledger ledger;

  LedgerChannel._(this.ledger);

  factory LedgerChannel() {
    final options = LedgerOptions(
      maxScanDuration: const Duration(milliseconds: 5000),
    );

    final ledger = Ledger(
      options: options,
      onPermissionRequest: () async {
        if (await Permission.location.request().isGranted) {
          // Location was granted, now request BLE
          Map<Permission, PermissionStatus> statuses = await [
            Permission.location,
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
            Permission.bluetoothAdvertise,
          ].request();

          print(statuses[Permission.location]);

          return statuses.values.where((status) => status.isDenied).isEmpty;
        }

        return false;
      },
    );

    return LedgerChannel._(ledger);
  }
}
