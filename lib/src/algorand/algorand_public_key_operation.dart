import 'dart:typed_data';

import 'package:algorand_dart/algorand_dart.dart';
import 'package:ledger_flutter/src/api/ble_request.dart';
import 'package:ledger_flutter/src/exceptions/ledger_exception.dart';
import 'package:ledger_flutter/src/utils/buffer.dart';

class AlgorandPublicKeyOperation extends BleRequest<String> {
  final int accountIndex;

  AlgorandPublicKeyOperation({
    this.accountIndex = 0,
  });

  @override
  Future<Uint8List> write(ByteDataWriter writer, int index, int mtu) async {
    writer.writeUint8(0x80); // ALGORAND_CLA
    writer.writeUint8(0x03); // PUBLIC_KEY_INS
    writer.writeUint8(0x00); // P1_FIRST
    writer.writeUint8(0x00); // P2_LAST
    writer.writeUint8(0x04); // ACCOUNT_INDEX_DATA_SIZE

    writer.writeUint32(accountIndex); // Account index as bytearray

    return writer.toBytes();
  }

  @override
  Future<String> read(ByteDataReader reader, int index, int mtu) async {
    try {
      return Address(publicKey: reader.read(reader.remainingLength))
          .encodedAddress;
    } catch (ex) {
      throw LedgerException('', ex);
    }
  }
}
