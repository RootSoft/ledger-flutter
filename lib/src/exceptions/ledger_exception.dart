class LedgerException implements Exception {
  String cause;
  Object? data;

  LedgerException([this.cause = '', this.data]);
}
