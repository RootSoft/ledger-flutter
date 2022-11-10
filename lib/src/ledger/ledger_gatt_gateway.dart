import 'dart:async';
import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ledger_flutter/ledger.dart';
import 'package:ledger_flutter/src/utils/buffer.dart';
import 'package:stack_trace/stack_trace.dart';

/// https://learn.adafruit.com/introduction-to-bluetooth-low-energy/gatt
/// https://gist.github.com/btchip/e4994180e8f4710d29c975a49de46e3a
class LedgerGattGateway extends GattGateway {
  /// Ledger Nano X service id
  static const serviceId = '13D63400-2C97-0004-0000-4C6564676572';

  static const writeCharacteristicKey = '13D63400-2C97-0004-0002-4C6564676572';
  static const notifyCharacteristicKey = '13D63400-2C97-0004-0001-4C6564676572';

  final FlutterReactiveBle bleManager;
  final BlePacker _packer;
  final DiscoveredLedger ledger;
  final LedgerGattReader _gattReader;

  DiscoveredCharacteristic? characteristicWrite;
  DiscoveredCharacteristic? characteristicNotify;
  int _mtu;

  /// The map of request ids to pending requests.
  final _pendingOperations = ListQueue<_Request>();
  final Function? _onError;

  LedgerGattGateway({
    required this.bleManager,
    required this.ledger,
    LedgerGattReader? gattReader,
    BlePacker? packer,
    int mtu = 23,
    Function? onError,
  })  : _gattReader = gattReader ?? LedgerGattReader(),
        _packer = packer ?? LedgerPacker(),
        _mtu = mtu,
        _onError = onError;

  @override
  Future<void> start() async {
    final supported = isRequiredServiceSupported();
    if (!supported) {
      throw LedgerException(message: 'Required service not supported');
    }

    _mtu = await bleManager.requestMtu(
      deviceId: ledger.device.id,
      mtu: 23,
    );

    final characteristic = QualifiedCharacteristic(
      serviceId: characteristicNotify!.serviceId,
      characteristicId: characteristicNotify!.characteristicId,
      deviceId: ledger.device.id,
    );

    _gattReader.read(
      bleManager.subscribeToCharacteristic(characteristic),
      onData: (data) async {
        if (_pendingOperations.isEmpty) {
          return;
        }

        try {
          final request = _pendingOperations.first;
          final reader = ByteDataReader();
          int offset = (data.length >= 2) ? 2 : 0;
          reader.add(data.sublist(0, data.length - offset));
          final response = await request.operation.read(reader, 0, _mtu);

          _pendingOperations.removeFirst();
          request.completer.complete(response);
        } catch (ex) {
          _handleOnError(ex);
          //_onError?.call(ex);
        }
      },
      onError: (ex) {
        _handleOnError(ex);
        _onError?.call(ex);
      },
    );
  }

  @override
  Future<void> disconnect() async {
    _gattReader.close();
    _pendingOperations.clear();
    ledger.disconnect();
  }

  @override
  Future<T> sendRequest<T>(LedgerOperation request) async {
    final supported = isRequiredServiceSupported();
    if (!supported) {
      throw LedgerException(message: 'Required service not supported');
    }

    final characteristic = QualifiedCharacteristic(
      serviceId: characteristicWrite!.serviceId,
      characteristicId: characteristicWrite!.characteristicId,
      deviceId: ledger.device.id,
    );

    const int index = 0x00;
    final payloadBuffer = ByteDataWriter();
    final payload = await request.write(payloadBuffer, index, _mtu);
    print('Payload: $payload');

    final packets = _packer.pack(payload, mtu);

    var completer = Completer<T>.sync();
    _pendingOperations.addFirst(_Request(request, completer, Chain.current()));

    for (var packet in packets) {
      await bleManager.writeCharacteristicWithResponse(
        characteristic,
        value: packet,
      );
    }

    return completer.future;
  }

  @override
  bool isRequiredServiceSupported() {
    characteristicWrite = null;
    characteristicNotify = null;

    getService(Uuid.parse(serviceId))?.let((service) {
      characteristicWrite =
          getCharacteristic(service, Uuid.parse(writeCharacteristicKey));
      characteristicNotify =
          getCharacteristic(service, Uuid.parse(notifyCharacteristicKey));
    });

    return characteristicWrite != null && characteristicNotify != null;
  }

  @override
  void onServicesInvalidated() {
    characteristicWrite = null;
    characteristicNotify = null;
  }

  /// Get the MTU.
  /// The Maximum Transmission Unit (MTU) is the maximum length of an ATT packet.
  int get mtu => _mtu;

  /// Returns a DiscoveredService, if the requested UUID is supported by the
  /// remote device.
  ///
  /// This function requires that service discovery has been completed for the
  /// given device.
  ///
  /// If multiple instances of the same service (as identified by UUID) exist,
  /// the first instance of the service is returned.
  /// For apps targeting Build.VERSION_CODES#R or lower, this requires
  /// the Manifest.permission#BLUETOOTH permission which can be gained with a
  /// simple <uses-permission> manifest tag.
  @override
  DiscoveredService? getService(Uuid service) {
    return ledger.services.firstWhereOrNull((s) => s.serviceId == service);
  }

  /// Returns a characteristic with a given UUID out of the list of
  /// characteristics offered by this service.
  ///
  /// This is a convenience function to allow access to a given characteristic
  /// without enumerating over the list returned by getCharacteristics()
  /// manually.
  ///
  /// If a remote service offers multiple characteristics with the same UUID,
  /// the first instance of a characteristic with the given UUID is returned.
  @override
  DiscoveredCharacteristic? getCharacteristic(
    DiscoveredService service,
    Uuid characteristic,
  ) {
    return service.characteristics
        .firstWhereOrNull((c) => c.characteristicId == characteristic);
  }

  @override
  Future<void> close() async {
    disconnect();
  }

  void _handleOnError(dynamic ex) {
    if (_pendingOperations.isEmpty) {
      return;
    }

    final request = _pendingOperations.removeFirst();
    request.completer.completeError(ex);
  }
}

/// A pending request to the server.
class _Request {
  /// The method that was sent.
  final LedgerOperation operation;

  /// The completer to use to complete the response future.
  final Completer completer;

  /// The stack chain from where the request was made.
  final Chain chain;

  _Request(this.operation, this.completer, this.chain);
}

extension ObjectExt<T> on T {
  R let<R>(R Function(T that) op) => op(this);
}
