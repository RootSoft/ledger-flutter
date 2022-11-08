import 'dart:typed_data';

import 'package:ledger_flutter/src/utils/buffer.dart';

abstract class LedgerOperation<T> {
  ///
  /// The Packet sequence index describes the current sequence for fragmented
  /// payloads.
  /// The first fragment index is 0x00 and increased in following packets.
  Future<Uint8List> write(ByteDataWriter writer, int index, int mtu);

  ///
  /// The Packet sequence index describes the current sequence for fragmented
  /// payloads.
  /// The first fragment index is 0x00 and increased in following packets.
  Future<T> read(ByteDataReader reader, int index, int mtu);
}
