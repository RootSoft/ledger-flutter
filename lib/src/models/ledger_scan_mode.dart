///Android only:  mode in which BLE discovery is executed.
enum LedgerScanMode {
  /// passively listen for other scan results without starting BLE scan itself.
  opportunistic,

  /// scanmode which has the lowest battery consumption.
  lowPower,

  /// scanmode that is a good compromise between battery consumption and latency.
  balanced,

  ///Scanmode with highest battery consumption and lowest latency.
  ///Should not be used when scanning for a long time.
  lowLatency,
}

/// Converts [ScanMode] to integer representation.
int convertScanModeToArgs(LedgerScanMode scanMode) {
  switch (scanMode) {
    case LedgerScanMode.opportunistic:
      return -1;
    case LedgerScanMode.lowPower:
      return 0;
    case LedgerScanMode.balanced:
      return 1;
    case LedgerScanMode.lowLatency:
      return 2;
  }
}
