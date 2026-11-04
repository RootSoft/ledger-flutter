import "dart:async";
import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus_dart.dart";

const _device = LedgerDevice(
  id: "test-device",
  name: "test",
  connectionType: ConnectionType.ble,
  deviceInfo: LedgerDeviceType.nanoX,
);

class _BlePlatform extends UniversalBlePlatform {
  bool connected = false;
  final writes = StreamController<Uint8List>.broadcast(sync: true);

  void loseConnection() {
    connected = false;
    updateConnection(_device.id, false);
  }

  void respond(List<int> packet) => updateCharacteristicValue(
        _device.id,
        _device.deviceInfo.notifyCharacteristicKey,
        Uint8List.fromList(packet),
        null,
      );

  @override
  Future<AvailabilityState> getBluetoothAvailabilityState() async => AvailabilityState.poweredOn;

  @override
  Future<BleConnectionState> getConnectionState(String deviceId) async =>
      connected ? BleConnectionState.connected : BleConnectionState.disconnected;

  @override
  Future<void> connect(String deviceId,
      {Duration? connectionTimeout, bool autoConnect = false, dynamic platformConfig}) async {
    connected = true;
    updateConnection(deviceId, true);
  }

  @override
  Future<void> disconnect(String deviceId) async => loseConnection();

  @override
  Future<List<BleService>> discoverServices(String deviceId, bool withDescriptors) async => [
        BleService(_device.deviceInfo.serviceId, [
          BleCharacteristic(_device.deviceInfo.writeCharacteristicKey, [CharacteristicProperty.write], []),
          BleCharacteristic(_device.deviceInfo.notifyCharacteristicKey, [CharacteristicProperty.notify], []),
        ]),
      ];

  @override
  Future<int> requestMtu(String deviceId, int expectedMtu) async => expectedMtu;

  @override
  Future<void> setNotifiable(String deviceId, String service, String characteristic, BleInputProperty property) async {}

  @override
  Future<void> writeValue(
    String deviceId,
    String service,
    String characteristic,
    Uint8List value,
    BleOutputProperty property,
  ) async =>
      writes.add(value);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ByteOperation extends LedgerRawOperation<int> {
  final int command;
  _ByteOperation(this.command);

  @override
  Future<List<Uint8List>> write(ByteDataWriter writer) async => [
        Uint8List.fromList([command])
      ];

  @override
  Future<int> read(ByteDataReader reader) async => reader.readUint8();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _BlePlatform platform;
  late LedgerBleConnectionManager manager;

  Future<LedgerConnection> connect() async {
    await manager.connect(_device);
    return LedgerConnection(manager, _device);
  }

  /// Sends [command] and waits until it reached the (fake) device.
  Future<Future<int>> send(LedgerConnection connection, int command) async {
    final written = platform.writes.stream.first;
    final response = connection.sendOperation(_ByteOperation(command));
    await written;
    return response;
  }

  setUp(() {
    platform = _BlePlatform();
    UniversalBle.setInstance(platform);
    manager = LedgerBleConnectionManager(onPermissionRequest: (_) async => true);
  });

  tearDown(() => manager.dispose());

  test("responses longer than 255 bytes use the full 16-bit length", () async {
    final response = await send(await connect(), 1);
    LedgerPacker().pack(Uint8List.fromList(List.filled(300, 42)), 23).forEach(platform.respond);
    expect(await response, 42);
  });

  test("losing the link fails the waiting request and queued ones, and a reconnect works", () async {
    final connection = await connect();
    final active = await send(connection, 1);
    final queued = connection.sendOperation(_ByteOperation(2));

    platform.loseConnection();

    await expectLater(active, throwsA(isA<ConnectionLostException>()));
    await expectLater(queued, throwsA(isA<DeviceNotConnectedException>()));
    expect(await manager.devices, isEmpty);

    final fresh = await send(await connect(), 3);
    platform.respond([5, 0, 0, 0, 1, 7]);
    expect(await fresh, 7);
  });

  test("an explicit disconnect fails the waiting request", () async {
    final connection = await connect();
    final active = await send(connection, 1);
    await connection.disconnect();
    await expectLater(active, throwsA(isA<ConnectionLostException>()));
  });
}
