import 'dart:typed_data';

abstract class BlePacker {
  List<Uint8List> pack(Uint8List payload, int mtu);
}
