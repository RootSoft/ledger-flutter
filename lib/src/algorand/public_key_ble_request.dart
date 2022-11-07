import 'dart:typed_data';

import 'package:ledger_flutter/src/api/ble_request.dart';
import 'package:ledger_flutter/src/utils/buffer.dart';

class PublicKeyBleRequest extends BleRequest {
  @override
  Future<Uint8List> payload(ByteDataWriter buffer, int index, int mtu) async {
    buffer.writeUint8(0x80); // ALGORAND_CLA
    buffer.writeUint8(0x03); // PUBLIC_KEY_INS
    buffer.writeUint8(0x00); // P1_FIRST
    buffer.writeUint8(0x00); // P2_LAST
    buffer.writeUint8(0x04); // ACCOUNT_INDEX_DATA_SIZE

    // TODO add acc index data size shr
    buffer.writeUint8(0x00); // Account index as bytearray
    buffer.writeUint8(0x00); // Account index as bytearray
    buffer.writeUint8(0x00); // Account index as bytearray
    buffer.writeUint8(0x00); // Account index as bytearray

    return buffer.toBytes();
  }
}
