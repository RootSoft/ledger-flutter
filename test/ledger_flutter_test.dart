import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus_dart.dart";

void main() {
  test("fromBleServices finds the Bluetooth device type by service uuid, ignoring case", () {
    const genericAccess = "00001800-0000-1000-8000-00805f9b34fb";
    for (final type in LedgerDeviceType.ble) {
      expect(LedgerDeviceType.fromBleServices([genericAccess, type.serviceId.toLowerCase()]), type);
    }
    expect(LedgerDeviceType.fromBleServices(["13D63400-2C97-3004-0000-4C6564676572"]), LedgerDeviceType.flex);
    expect(LedgerDeviceType.fromBleServices([]), isNull);
    expect(LedgerDeviceType.fromBleServices([genericAccess]), isNull);
  });

  test("LedgerSimpleOperation sets its debug name, so debug printing works", () async {
    LedgerSimpleOperation op({String? debugName}) => LedgerSimpleOperation(
        cla: 0xe0, ins: 1, p1: 0, p2: 0, data: Uint8List(0), prependDataLength: false, debugName: debugName);

    expect(op().debugName, "LedgerSimpleOperation");
    expect(op(debugName: "getVersion").debugName, "getVersion");

    debugPrintEnabled = true;
    addTearDown(() => debugPrintEnabled = false);
    expect(await op().write(ByteDataWriter()), [
      [0xe0, 1, 0, 0]
    ]);
  });
}
