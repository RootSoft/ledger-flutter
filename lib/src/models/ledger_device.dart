class LedgerDevice {
  final String id;
  final String address;
  final String name;
  final int rssi;

  LedgerDevice({
    required this.id,
    required this.address,
    required this.name,
    required this.rssi,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
