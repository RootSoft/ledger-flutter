import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class LedgerOptions {
  final Duration maxScanDuration;

  /// The [prescanDuration] is the amount of time BLE disovery should run in
  /// order to find the device.
  final Duration prescanDuration;

  /// If [connectionTimeout] parameter is supplied and a connection is not
  /// established before [connectionTimeout] expires, the pending connection
  /// attempt will be cancelled and a [TimeoutException] error will be emitted
  /// into the returned stream.
  final Duration connectionTimeout;

  /// The [scanMode] allows to choose between different levels of power efficient
  /// and/or low latency scan modes.
  final ScanMode scanMode;

  /// [requireLocationServicesEnabled] specifies whether to check if location
  /// services are enabled before scanning.
  ///
  /// When set to true and location services are disabled, an exception is thrown.
  /// Default is true.
  /// Setting the value to false can result in not finding BLE peripherals on
  /// some Android devices.
  final bool requireLocationServicesEnabled;

  LedgerOptions({
    this.scanMode = ScanMode.lowPower,
    this.requireLocationServicesEnabled = true,
    this.maxScanDuration = const Duration(milliseconds: 15000),
    this.prescanDuration = const Duration(seconds: 5),
    this.connectionTimeout = const Duration(seconds: 2),
  });
}
