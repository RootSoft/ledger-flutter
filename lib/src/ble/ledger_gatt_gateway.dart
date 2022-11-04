import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ledger_flutter/src/ble/ble_request.dart';
import 'package:ledger_flutter/src/ble/gatt_gateway.dart';
import 'package:ledger_flutter/src/exceptions/ledger_exception.dart';
import 'package:ledger_flutter/src/models/discovered_ledger.dart';

/// https://learn.adafruit.com/introduction-to-bluetooth-low-energy/gatt
class LedgerGattGateway extends GattGateway {
  /// Ledger Nano X service id
  static const serviceId = '13D63400-2C97-0004-0000-4C6564676572';

  static const writeCharacteristicKey = '13D63400-2C97-0004-0002-4C6564676572';
  static const notifyCharacteristicKey = '13D63400-2C97-0004-0001-4C6564676572';

  final FlutterReactiveBle bleManager;
  final DiscoveredLedger ledger;

  DiscoveredCharacteristic? characteristicWrite;
  DiscoveredCharacteristic? characteristicNotify;
  StreamSubscription? notification;

  LedgerGattGateway({
    required this.bleManager,
    required this.ledger,
  });

  @override
  Future<void> start() async {
    final supported = isRequiredServiceSupported();
    if (!supported) {
      throw LedgerException('Required service not supported');
    }

    final negotiated = await bleManager.requestMtu(
      deviceId: ledger.device.id,
      mtu: 23,
    );

    print(negotiated);
    print(Uuid.parse(serviceId));
    print(characteristicNotify!.serviceId);

    final characteristic = QualifiedCharacteristic(
      serviceId: characteristicNotify!.serviceId,
      characteristicId: characteristicNotify!.characteristicId,
      deviceId: ledger.device.id,
    );

    notification =
        bleManager.subscribeToCharacteristic(characteristic).listen((event) {
      print('Event received');
      print(event);
    }, onError: (ex) {
      print(ex);
    });

    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> disconnect() async {
    notification?.cancel();
    ledger.disconnect();
  }

  @override
  Future<void> sendRequest(BleRequest request) async {
    final supported = isRequiredServiceSupported();
    if (!supported) {
      throw LedgerException('Required service not supported');
    }

    final characteristic = QualifiedCharacteristic(
      serviceId: characteristicWrite!.serviceId,
      characteristicId: characteristicWrite!.characteristicId,
      deviceId: ledger.device.id,
    );

    final payload = await request.payload(0x00);
    await bleManager.writeCharacteristicWithResponse(
      characteristic,
      value: payload,
    );
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
}

extension ObjectExt<T> on T {
  R let<R>(R Function(T that) op) => op(this);
}
