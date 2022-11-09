import 'dart:typed_data';

import 'package:ledger_flutter/src/ledger/ledger_operation.dart';
import 'package:ledger_flutter/src/utils/buffer.dart';

/// APDU Protocol
/// https://github.com/LedgerHQ/app-algorand/blob/develop/docs/APDUSPEC.md
class AlgorandSignMsgPackTransaction extends LedgerOperation<Uint8List> {
  static const HEADER_SIZE = 5;
  static const CHUNK_SIZE = 0xFF;

  static const P1_FIRST_WITH_ACCOUNT = 0x01;
  static const P1_MORE = 0x80;
  static const P2_MORE = 0x80;
  static const P2_LAST = 0x00;

  final int accountIndex;
  final Uint8List transaction;

  AlgorandSignMsgPackTransaction({
    required this.transaction,
    this.accountIndex = 0,
  });

  @override
  Future<Uint8List> write(ByteDataWriter writer, int index, int mtu) async {
    var bytesRemaining = transaction.length + 0x04;
    var offset = 0;
    var p1 = P1_FIRST_WITH_ACCOUNT;
    var p2 = P2_MORE;

    while (bytesRemaining > 0) {
      final bytesRemainingWithHeader = bytesRemaining + HEADER_SIZE;
      final packetSize = bytesRemainingWithHeader <= CHUNK_SIZE
          ? bytesRemainingWithHeader
          : CHUNK_SIZE;

      final remainingSpace = packetSize - HEADER_SIZE;
      var bytesToCopyLength =
          (remainingSpace < bytesRemaining) ? remainingSpace : bytesRemaining;
      bytesRemaining -= bytesToCopyLength;
      if (bytesRemaining == 0) {
        p2 = P2_LAST;
      }

      writer.writeUint8(0x80);
      writer.writeUint8(0x08);

      // If one single APDU may contain a whole transaction, P1 and P2 are both 0x00.
      writer.writeUint8(p1);
      writer.writeUint8(p2);
      writer.writeUint8(bytesToCopyLength);
      if (p1 == P1_FIRST_WITH_ACCOUNT) {
        writer.writeUint32(accountIndex);
        bytesToCopyLength -= 4;
      }

      writer.write(
          transaction.getRange(offset, offset + bytesToCopyLength).toList());
      offset += bytesToCopyLength;

      p1 = P1_MORE;
    }

    return writer.toBytes();
  }

  @override
  Future<Uint8List> read(
    ByteDataReader reader,
    int index,
    int mtu,
  ) async {
    // Read the signature
    return reader.read(reader.remainingLength);
  }
}
