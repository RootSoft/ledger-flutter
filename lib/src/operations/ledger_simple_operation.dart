import "dart:typed_data";

import "../../ledger_flutter_plus_dart.dart";

class LedgerSimpleOperation extends LedgerRawOperation<ByteDataReader> {
  late final String debugName;

  final int cla;
  final int ins;
  final int p1;
  final int p2;
  final Uint8List data;
  final bool prependDataLength;

  LedgerSimpleOperation({
    required this.cla,
    required this.ins,
    required this.p1,
    required this.p2,
    required this.data,
    required this.prependDataLength,
    String? debugName,
  }) {
    // ignore: no_runtimetype_tostring
    this.debugName = debugName ?? runtimeType.toString();
  }

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) {
    writer.writeUint8(cla);
    writer.writeUint8(ins);
    writer.writeUint8(p1);
    writer.writeUint8(p2);
    if (prependDataLength) {
      writer.writeUint8(data.length);
    }
    if (data.isNotEmpty) {
      writer.write(data);
    }

    if (debugPrintEnabled) {
      // ignore: avoid_print
      print("$debugName: ${hex.encode(writer.toBytes())}");
    }
    return Future.value([writer.toBytes()]);
  }

  @override
  Future<ByteDataReader> read(ByteDataReader reader) async => reader;
}
