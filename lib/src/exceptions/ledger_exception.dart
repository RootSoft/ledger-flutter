import 'package:flutter/services.dart';

class LedgerException implements Exception {
  final String message;
  final Object? cause;
  final int errorCode;

  LedgerException({
    this.message = '',
    this.cause,
    this.errorCode = 0x6F00,
  });

  factory LedgerException.fromPlatformException(PlatformException exception) {
    final errorCode = int.tryParse(exception.code) ?? 0;
    final message = exception.message ?? '';
    return LedgerException(
      errorCode: errorCode,
      message: message,
      cause: exception,
    );
  }
}
