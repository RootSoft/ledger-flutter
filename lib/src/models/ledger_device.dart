class LedgerDevice {
  final String id;
  final String name;
  final int rssi;

  LedgerDevice({
    required this.id,
    required this.name,
    this.rssi = 0,
  });

  LedgerDevice copyWith({
    String Function()? id,
    String Function()? name,
    int Function()? rssi,
  }) {
    return LedgerDevice(
      id: id != null ? id() : this.id,
      name: name != null ? name() : this.name,
      rssi: rssi != null ? rssi() : this.rssi,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
