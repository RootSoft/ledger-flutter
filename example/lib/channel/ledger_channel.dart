import 'package:algorand_dart/algorand_dart.dart';
import 'package:ledger_flutter/ledger.dart';
import 'package:permission_handler/permission_handler.dart';

class LedgerChannel {
  final Ledger ledger;
  final Algorand algorand;

  LedgerChannel._(this.ledger, this.algorand);

  factory LedgerChannel() {
    final options = LedgerOptions(
      maxScanDuration: const Duration(milliseconds: 5000),
    );

    final ledger = Ledger(
      options: options,
      onPermissionRequest: (status) async {
        // Location was granted, now request BLE
        Map<Permission, PermissionStatus> statuses = await [
          Permission.location,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        if (status != BleStatus.ready) {
          return false;
        }

        return statuses.values.where((status) => status.isDenied).isEmpty;
      },
    );

    final algorand = Algorand(
      algodClient: AlgodClient(
        apiUrl: AlgoExplorer.MAINNET_ALGOD_API_URL,
      ),
    );

    return LedgerChannel._(ledger, algorand);
  }
}
