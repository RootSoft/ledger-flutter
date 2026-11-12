import "package:flutter/foundation.dart";

import "../../ledger_flutter_plus.dart";

@immutable
class BleConnectionChangeEvent {
  final String deviceId;
  final BleConnectionState newState;

  const BleConnectionChangeEvent({
    required this.deviceId,
    required this.newState,
  });

  @override
  String toString() {
    return "ConnectionChangeEvent{deviceId: $deviceId, newState: $newState}";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BleConnectionChangeEvent && other.deviceId == deviceId && other.newState == newState;
  }

  @override
  int get hashCode => Object.hash(deviceId, newState);
}
