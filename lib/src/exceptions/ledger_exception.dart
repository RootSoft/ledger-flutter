class LedgerException implements Exception {
  final String message;
  final Object? cause;
  final int errorCode;

  LedgerException({
    this.message = '',
    this.cause,
    this.errorCode = 0x6F00,
  });
}
