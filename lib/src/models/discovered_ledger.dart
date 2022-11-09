import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ledger_flutter/ledger.dart';

class DiscoveredLedger {
  final LedgerDevice device;
  final StreamSubscription? subscription;
  final List<DiscoveredService> services;

  DiscoveredLedger({
    required this.device,
    required this.subscription,
    required this.services,
  });

  Future<void> disconnect() async {
    subscription?.cancel();
  }
}
