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
    LedgerTransformer? transformer,
  ) async {
    try {
      final writer = ByteDataWriter();
      final apdus = await operation.write(writer);
      final response = await _ledgerUsb.exchange(apdus);
      final reader = ByteDataReader();
      if (transformer != null) {
        final transformed = await transformer.onTransform(response);
        reader.add(transformed);
      } else {
        reader.add(response.expand((e) => e).toList());
      }

      return operation.read(reader);
    } on PlatformException catch (ex) {
      throw LedgerException.fromPlatformException(ex);
    }
  }
}
