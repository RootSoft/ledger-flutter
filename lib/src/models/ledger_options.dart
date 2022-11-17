import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class LedgerOptions {
  /// The [maxScanDuration] is the maximum amount of time BLE discovery should
  /// run in order to find nearby devices.
  final Duration maxScanDuration;

  /// The [prescanDuration] is the amount of time BLE discovery should run in
  /// order to find the device before connecting.
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

  /// Maximum Transmission Unit, [mtu] is the maximum length of an ATT packet
  /// and is negotiated between the host and client, before sending APDU messages.
  final int mtu;

  LedgerOptions({
    this.scanMode = ScanMode.lowPower,
    this.requireLocationServicesEnabled = true,
    this.maxScanDuration = const Duration(milliseconds: 15000),
    this.prescanDuration = const Duration(seconds: 5),
    this.connectionTimeout = const Duration(seconds: 2),
    this.mtu = 23,
  });

  LedgerOptions copyWith({
    ScanMode Function()? scanMode,
    bool Function()? requireLocationServicesEnabled,
    Duration Function()? maxScanDuration,
    Duration Function()? prescanDuration,
    Duration Function()? connectionTimeout,
    int Function()? mtu,
  }) {
    return LedgerOptions(
      scanMode: scanMode != null ? scanMode() : this.scanMode,
      requireLocationServicesEnabled: requireLocationServicesEnabled != null
          ? requireLocationServicesEnabled()
          : this.requireLocationServicesEnabled,
      maxScanDuration:
          maxScanDuration != null ? maxScanDuration() : this.maxScanDuration,
      prescanDuration:
          prescanDuration != null ? prescanDuration() : this.prescanDuration,
      connectionTimeout: connectionTimeout != null
          ? connectionTimeout()
          : this.connectionTimeout,
      mtu: mtu != null ? mtu() : this.mtu,
    );
  }
}
