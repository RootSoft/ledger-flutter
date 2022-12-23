import 'dart:typed_data';

abstract class LedgerTransformer {
  const LedgerTransformer();

  Future<Uint8List> onTransform(List<Uint8List> transform);
}
