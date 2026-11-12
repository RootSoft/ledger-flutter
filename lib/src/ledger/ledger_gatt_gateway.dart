import "dart:async";
import "dart:collection";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:universal_platform/universal_platform.dart";

import "../../ledger_flutter_plus.dart";
import "../operations/ledger_operations.dart";

const _bleWriteTimeout = Duration(seconds: 10);

class LedgerGattGateway extends GattGateway {
  final BlePacker _packer;
  final DiscoveredLedger ledger;
  final LedgerGattReader _gattReader;

  BleCharacteristic? characteristicWrite;
  BleCharacteristic? characteristicNotify;
  int _mtu;

  final _pendingOperations = ListQueue<_Request>();
  final Function(Object)? _onError;

  bool _disposed = false;

  LedgerGattGateway({
    required this.ledger,
    LedgerGattReader? gattReader,
    BlePacker? packer,
    int mtu = 23,
    Function(Object)? onError,
  })  : _gattReader = gattReader ?? LedgerGattReader(),
        _packer = packer ?? LedgerPacker(),
        _mtu = mtu,
        _onError = onError;

  /// Pair the device if needed.
  Future<void> _pairDeviceIfNeeded() async {
    /// [Android] Pairing seems to work well
    if (!UniversalPlatform.isAndroid) {
      /// [iOS] Pairing HANGS ENDLESSLY ; seems to work well without requesting explicit pairing
      /// [Web] Not sure what happens ; seems to work well without requesting explicit pairing
      return;
    }

    final isPaired = await UniversalBle.isPaired(
      ledger.device.id,
      pairingCommand: BleCommand(
        service: ledger.device.deviceInfo.serviceId,
        characteristic: ledger.device.deviceInfo.writeCharacteristicKey,
      ),
    );

    if (isPaired == false) {
      await UniversalBle.pair(
        ledger.device.id,
        pairingCommand: UniversalPlatform.isAndroid
            ? null
            : BleCommand(
                service: ledger.device.deviceInfo.serviceId,
                characteristic: ledger.device.deviceInfo.writeCharacteristicKey,
              ),
      );
    }
  }

  @override
  Future<void> start() async {
    try {
      final supported = await isRequiredServiceSupported();
      if (!supported) {
        throw ServiceNotSupportedException(
          connectionType: ConnectionType.ble,
          message: "Required service not supported. "
              "Write characteristic: ${characteristicWrite != null}, "
              "Notify characteristic: ${characteristicNotify != null}",
        );
      }

      if (UniversalPlatform.isWeb) {
        _mtu = 23;
      } else {
        try {
          _mtu = await UniversalBle.requestMtu(ledger.device.id, _mtu);
        } catch (e) {
          _mtu = 23;
        }
      }

      await _pairDeviceIfNeeded();

      try {
        if (characteristicNotify != null && characteristicNotify!.properties.contains(CharacteristicProperty.notify)) {
          await UniversalBle.subscribeNotifications(
            ledger.device.id,
            ledger.device.deviceInfo.serviceId,
            ledger.device.deviceInfo.notifyCharacteristicKey,
          );
        } else {
          throw ServiceNotSupportedException(
            connectionType: ConnectionType.ble,
            message: "Notify characteristic does not support notifications",
          );
        }
      } catch (e) {
        throw ServiceNotSupportedException(
          connectionType: ConnectionType.ble,
          message: "Failed to set notifiable: $e",
        );
      }

      // TODO this would cause issues if we have multiple gatt gateway instances in parallel
      final deviceId = UniversalBle.canonicalDeviceId(ledger.device.id);
      UniversalBle.onValueChange = (value) async {
        if (_disposed || value.deviceId != deviceId) {
          return;
        }
        final rawData = value.value;

        if (_pendingOperations.isEmpty) {
          if (!_disposed) {
            // if not disposed, this is a WTF level error
            _onError?.call(
              UnexpectedDataPacketException(
                reason: UnexpectedDataPacketReason.receivedLedgerDataWithNoPendingRequest,
                connectionType: ConnectionType.ble,
              ),
            );
          }
          return;
        }

        // Remove exactly this request when done (not whatever is first by then): while we await below, sendOperation
        // may drop it after a failed write and queue the next request.
        final request = _pendingOperations.first;
        try {
          request.addData(rawData);

          if (!request.isComplete) {
            return;
          }
          final data = request.data;

          final transformer = request.transformer;
          final reader = ByteDataReader();
          if (transformer != null) {
            final transformed = await transformer.onTransform([data]);
            reader.add(transformed);
          } else {
            reader.add(data);
          }

          final response = await request.operation.read(reader);

          // An overlapping callback (e.g. a malformed or duplicate packet) may already have failed this request.
          _pendingOperations.remove(request);
          if (!request.completer.isCompleted) {
            request.completer.complete(response);
          }
        } catch (ex) {
          _pendingOperations.remove(request);
          if (!request.completer.isCompleted) {
            request.completer.completeError(ex);
          }
          _onError?.call(ex);
        }
      };
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  /// Fails every waiting request with [ConnectionLostException], so callers never hang on a dead link.
  /// Does not touch the BLE link itself.
  void connectionLost() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_gattReader.close());
    final error = ConnectionLostException(connectionType: ConnectionType.ble);
    while (_pendingOperations.isNotEmpty) {
      final request = _pendingOperations.removeFirst();
      if (!request.completer.isCompleted) request.completer.completeError(error);
    }
  }

  @override
  Future<void> disconnect() async {
    connectionLost();
    await UniversalBle.disconnect(ledger.device.id);
  }

  @override
  Future<T> sendOperation<T>(
    LedgerRawOperation operation, {
    LedgerTransformer? transformer,
  }) async {
    final supported = await isRequiredServiceSupported();
    if (_disposed) throw ConnectionLostException(connectionType: ConnectionType.ble);
    if (!supported) {
      throw ServiceNotSupportedException(
        connectionType: ConnectionType.ble,
        message: "Required service not supported. "
            "Write characteristic: ${characteristicWrite != null}, "
            "Notify characteristic: ${characteristicNotify != null}",
      );
    }

    final completer = Completer<T>.sync();
    // The device can answer (e.g. wrong app, locked, still in call) before the last packet write is acknowledged,
    // completing the completer with an error while nobody listens to its future yet. Without `ignore()` that error
    // would be reported as uncaught. Ignoring only marks the future as handled; the caller still receives the
    // error because we return this same future below.
    final response = completer.future;
    response.ignore();

    final request = _Request(operation, transformer, completer);
    _pendingOperations.addFirst(request);

    try {
      final writer = ByteDataWriter();
      final output = await operation.write(writer);
      for (final payload in output) {
        final packets = _packer.pack(payload, _mtu);

        for (final packet in packets) {
          await UniversalBle.write(
            ledger.device.id,
            ledger.device.deviceInfo.serviceId,
            characteristicWrite!.uuid,
            packet,
            withoutResponse: false,
            timeout: _bleWriteTimeout,
          );
        }
      }
    } catch (_) {
      // The request was never fully sent, so no response will arrive for it. Drop it to avoid a stale pending request
      // that would swallow the response of the next operation.
      _pendingOperations.remove(request);
      rethrow;
    }

    return response;
  }

  @override
  Future<bool> isRequiredServiceSupported() async {
    characteristicWrite = null;
    characteristicNotify = null;

    try {
      final bleDeviceInfo = ledger.device.deviceInfo;
      final service = await getService(bleDeviceInfo.serviceId);
      if (service != null) {
        characteristicWrite = await getCharacteristic(
          service,
          bleDeviceInfo.writeCharacteristicKey,
        );
        characteristicNotify = await getCharacteristic(
          service,
          bleDeviceInfo.notifyCharacteristicKey,
        );
      }
    } catch (e) {
      throw ServiceNotSupportedException(
        connectionType: ConnectionType.ble,
        nestedError: e,
        message: "Required service not supported. "
            "Write characteristic: ${characteristicWrite != null}, "
            "Notify characteristic: ${characteristicNotify != null}",
      );
    }

    final isSupported = characteristicWrite != null &&
        characteristicNotify != null &&
        characteristicWrite!.properties.contains(CharacteristicProperty.write) &&
        characteristicNotify!.properties.contains(CharacteristicProperty.notify);
    return isSupported;
  }

  @override
  Future<BleCharacteristic?> getCharacteristic(
    BleService service,
    String characteristic,
  ) async {
    try {
      final targetUuid = characteristic.toLowerCase();
      final result = service.characteristics.firstWhere(
        (c) => c.uuid.toLowerCase() == targetUuid,
        orElse: () => throw Exception("Characteristic not found"),
      );
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  void onServicesInvalidated() {
    characteristicWrite = null;
    characteristicNotify = null;
  }

  int get mtu => _mtu;

  @override
  Future<BleService?> getService(String serviceId) async {
    try {
      final services = await UniversalBle.discoverServices(ledger.device.id);

      final targetUuid = serviceId.toLowerCase();

      final foundService = services.firstWhere(
        (s) => s.uuid.toLowerCase() == targetUuid || s.uuid.toLowerCase().startsWith(targetUuid),
        orElse: () => throw Exception("Service not found"),
      );

      return foundService;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    await disconnect();
  }
}

class _Request {
  final LedgerRawOperation operation;
  final LedgerTransformer? transformer;
  final Completer completer;

  final Map<int, Uint8List> _partialData = {};
  int _expectedDataLength = -1; // read from packet 0

  void addData(Uint8List data) {
    // First packet should be at least 5 bytes long
    // Rest should be at least 3 bytes long
    // Frame header: tag (1 byte), packet index (big-endian u16), and on packet 0 the total length (big-endian u16)
    final packetIndex = data.length < 3 ? -1 : (data[1] << 8) | data[2];
    if (packetIndex < 0 || (packetIndex == 0 && data.length < 5)) {
      throw UnexpectedDataPacketException(
        data: data,
        reason: UnexpectedDataPacketReason.tooShortLength,
        connectionType: ConnectionType.ble,
      );
    }
    if (_partialData.containsKey(packetIndex)) {
      throw UnexpectedDataPacketException(
        reason: UnexpectedDataPacketReason.indexAlreadySet,
        connectionType: ConnectionType.ble,
      );
    }

    if (packetIndex == 0) {
      if (_expectedDataLength != -1) {
        throw UnexpectedDataPacketException(
          reason: UnexpectedDataPacketReason.dataLengthAlreadySet,
          connectionType: ConnectionType.ble,
        );
      }
      _expectedDataLength = (data[3] << 8) | data[4];
    }

    // for first packet, skip the first 5 bytes | for the rest, skip the first 3 bytes
    final noPrefixData = data.sublist(packetIndex == 0 ? 5 : 3);
    if (noPrefixData.isNotEmpty) {
      // I think for all requests we get a last empty packet with just the index
      // -- Not sure if this is always the case so I will ignore it for now
      _partialData[packetIndex] = noPrefixData;
    }
  }

  int get expectedDataLength => _expectedDataLength;

  int get currentDataLength => _partialData.values.fold(0, (acc, e) => acc + e.length);

  bool get isComplete => currentDataLength == expectedDataLength;

  Uint8List get data {
    final data = _partialData.entries
        .sortedByCompare((e) => e.key, (a, b) => a.compareTo(b))
        .map((e) => e.value)
        .expand((e) => e)
        .toList();
    return Uint8List.fromList(data);
  }

  _Request(this.operation, this.transformer, this.completer);
}

extension ObjectExt<T> on T {
  R let<R>(R Function(T that) op) => op(this);
}
