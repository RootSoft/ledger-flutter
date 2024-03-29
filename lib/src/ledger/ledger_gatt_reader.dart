import 'dart:async';
import 'dart:typed_data';

import 'package:ledger_flutter/src/exceptions/ledger_exception.dart';
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

  static const errorDataSize = 2;

  var currentSequence = 0;
  var remainingBytes = 0;
  var payload = <int>[];

  StreamSubscription? subscription;

  void read(
    Stream<List<int>> stream, {
    void Function(Uint8List event)? onData,
    Function? onError,
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
          _handleData(
            Uint8List.fromList(payload),
            onData: onData,
            onError: onError,
          );
        } else if (remainingBytes > 0) {
          // wait for next message
          currentSequence += 1;
        } else {
          reset();
        }
      },
      onError: (ex) {
        onError?.call(ex);
      },
    );
  }

  void _handleData(
    Uint8List data, {
    void Function(Uint8List event)? onData,
    Function? onError,
  }) {
    reset();

    if (data.length > errorDataSize) {
      onData?.call(data);
    } else if (data.length == errorDataSize) {
      final errorCode = ByteData.sublistView(data).getInt16(0);
      onError?.call(LedgerException(errorCode: errorCode));
    } else {
      onError?.call(LedgerException());
    }
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
