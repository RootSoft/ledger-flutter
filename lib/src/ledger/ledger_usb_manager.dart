import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ledger_flutter/ledger.dart';
import 'package:ledger_usb/ledger_usb.dart';
import 'package:ledger_usb/usb_device.dart';

class LedgerUsbManager extends UsbManager {
  final _ledgerUsb = LedgerUsb();

  @override
  Future<List<LedgerDevice>> listDevices() async {
    try {
      final devices = await _ledgerUsb.listDevices();
      return devices
          .map((device) => LedgerDevice.fromUsbDevice(device))
          .toList();
    } on PlatformException catch (ex) {
      throw LedgerException.fromPlatformException(ex);
    }
  }

  @override
  Future<void> connect(LedgerDevice device, {LedgerOptions? options}) async {
    try {
      final usbDevice = UsbDevice.fromIdentifier(device.id);
      await _ledgerUsb.requestPermission(usbDevice);
      await _ledgerUsb.open(usbDevice);
    } on PlatformException catch (ex) {
      throw LedgerException.fromPlatformException(ex);
    }
  }

  @override
  Future<void> disconnect(LedgerDevice device) async {
    try {
      await _ledgerUsb.close();
    } on PlatformException catch (ex) {
      throw LedgerException.fromPlatformException(ex);
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _ledgerUsb.close();
    } on PlatformException catch (ex) {
      throw LedgerException.fromPlatformException(ex);
    }
  }

  @override
  Future<T> sendOperation<T>(
    LedgerDevice device,
    LedgerOperation<T> operation,
  ) async {
    try {
      final writer = ByteDataWriter();
      final apdus = await operation.write(writer);
      final response = await _ledgerUsb.exchange(apdus);

      if (response.length == apdus.length * 2) {
        final errorCode = ByteData.sublistView(response).getInt16(0);
        throw LedgerException(errorCode: errorCode);
      } else if (response.isEmpty) {
        throw LedgerException(message: 'Empty response.');
      }

      final reader = ByteDataReader();
      reader.add(response);
      return operation.read(reader);
    } on PlatformException catch (ex) {
      throw LedgerException.fromPlatformException(ex);
    }
  }
}
