import 'dart:typed_data';

abstract class BleRequest {
  ///
  /// The Packet sequence index describes the current sequence for fragmented
  /// payloads.
  /// The first fragment index is 0x00 and increased in following packets.
  Future<Uint8List> payload(int index);
}
