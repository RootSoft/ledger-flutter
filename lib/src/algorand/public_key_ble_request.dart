import 'dart:typed_data';

import 'package:ledger_flutter/src/ble/ble_request.dart';
import 'package:ledger_flutter/src/utils/buffer.dart';

class PublicKeyBleRequest extends BleRequest {
  @override
  Future<Uint8List> payload(int index) async {
    final payload = ByteDataWriter();
    payload.writeUint8(0x80); // ALGORAND_CLA
    payload.writeUint8(0x03); // PUBLIC_KEY_INS
    payload.writeUint8(0x00); // P1_FIRST
    payload.writeUint8(0x00); // P2_LAST
    payload.writeUint8(0x04); // ACCOUNT_INDEX_DATA_SIZE

    // TODO add acc index data size shr
    payload.writeUint8(0x00); // Account index as bytearray
    payload.writeUint8(0x00); // Account index as bytearray
    payload.writeUint8(0x00); // Account index as bytearray
    payload.writeUint8(0x00); // Account index as bytearray

    final payloadLength = payload.toBytes().length;

    final buffer = ByteDataWriter();
    buffer.writeUint8(0x05); // Command / DATA_CLA
    buffer.writeUint16(index); // packet sequence index
    buffer.writeUint16(payloadLength); // data length
    buffer.write(payload.toBytes()); // payload

    // TODO
    final data = buffer.toBytes();
    print(data);
    return data;
  }
}
