import 'dart:async';
import 'dart:typed_data';

import 'package:ledger_flutter/src/utils/buffer.dart';

class LedgerGattReader {
  /// The APDU command tag 0x05 is used to transfer application specific data.
  static const dataCla = 0x05;

  /// The GET MTU command tag 0x08 is used to query the negociated MTU and
  /// optimize the size of fragments
  static const mtuCla = 0x08;

  /// The GET VERSION command tag 0x00 is used to query the current version of
  /// the protocol being used
  static const versionCla = 0x00;

  var currentSequence = 0;
  var remainingBytes = 0;
  var payload = <int>[];

  StreamSubscription? subscription;

  void read(
    Stream<List<int>> stream, {
    required void Function(Uint8List event) onData,
    required void Function(Object exception) onError,
  }) {
    subscription?.cancel();
    subscription = stream.listen(
      (data) {
        // Packets always start with the command & sequence
        final reader = ByteDataReader();
        reader.add(data);
        final command = reader.readUint8();

        if (command != dataCla) {
          return;
        }

        final sequence = reader.readUint16();

        if (sequence != currentSequence) {
          reset();
          return;
        }

        if (currentSequence == 0) {
          // Read the length
          remainingBytes = reader.readUint16();
        }

        remainingBytes -= reader.remainingLength;
        payload.addAll(reader.read(reader.remainingLength));

        if (remainingBytes == 0) {
          final data = Uint8List.fromList(payload);
          reset();

          onData(data);
        } else if (remainingBytes > 0) {
          // wait for next message
          currentSequence += 1;
        } else {
          reset();
        }
      },
      onError: (ex) {
        onError.call(ex);
      },
    );
  }

  /// Reset the reader
  void reset() {
    currentSequence = 0;
    remainingBytes = 0;
    payload = <int>[];
  }

  Future<void> close() async {
    reset();

    subscription?.cancel();
  }
}
