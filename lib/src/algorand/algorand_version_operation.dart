import 'dart:typed_data';

import 'package:ledger_flutter/src/algorand/algorand_version.dart';
import 'package:ledger_flutter/src/ledger/ledger_operation.dart';
import 'package:ledger_flutter/src/utils/buffer.dart';

/// GET VERSION APDU PROTOCOL:
///
/// https://github.com/LedgerHQ/app-algorand/blob/develop/docs/APDUSPEC.md#get_version
class AlgorandVersionOperation extends LedgerOperation<AlgorandVersion> {
  AlgorandVersionOperation();

  @override
  Future<Uint8List> write(ByteDataWriter writer, int index, int mtu) async {
    writer.writeUint8(0x80); // ALGORAND_CLA
    writer.writeUint8(0x00); // PUBLIC_KEY_INS
    writer.writeUint8(0x00); // P1_FIRST
    writer.writeUint8(0x00); // P2_LAST
    writer.writeUint8(0x00); // ACCOUNT_INDEX_DATA_SIZE

    return writer.toBytes();
  }

  @override
  Future<AlgorandVersion> read(
    ByteDataReader reader,
    int index,
    int mtu,
  ) async {
    final testMode = reader.readUint8();
    final versionMajor = reader.readUint16();
    final versionMinor = reader.readUint16();
    final versionPatch = reader.readUint16();
    final locked = reader.readUint8();

    return AlgorandVersion(
      testMode: testMode != 0,
      versionMajor: versionMajor,
      versionMinor: versionMinor,
      versionPatch: versionPatch,
      locked: locked != 0,
    );
  }
}
