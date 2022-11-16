<br />
<div align="center">
  <a href="https://www.ledger.com/">
    <img src="https://cdn1.iconfinder.com/data/icons/minicons-4/64/ledger-512.png" width="100"/>
  </a>

<h1 align="center">ledger-flutter</h1>

<p align="center">
    A Flutter plugin to scan, connect & sign transactions using a Ledger Nano X
    <br />
    <a href="https://pub.dev/documentation/ledger_flutter/latest/"><strong>« Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/RootSoft/ledger-flutter/issues">Report Bug</a>
    · <a href="https://github.com/RootSoft/ledger-flutter/issues">Request Feature</a>
  </p>
</div>
<br/>

---

## Overview

The Ledger Nano X is the perfect hardware wallet for managing your crypto & NFTs on the go.
This Flutter plugin makes it easy to find nearby Ledger devices, connect with them and sign transactions over BLE.

### Web3 Ecosystem Integrations

We are expanding the Flutter ecosystem to grow the Web3 community.
Check out our other Web3 packages below:

- [WalletConnect](https://pub.dev/packages/walletconnect_dart)
- [Reach](https://pub.dev/packages/reach_dart)
- [Algorand](https://pub.dev/packages/algorand_dart)


## Getting started

### Installation

Install the latest version of this package via pub.dev:

```yaml
ledger_flutter: ^latest-version
```

You might want to install additional Ledger App Plugins to support different blockchains. See the [Ledger Plugins]() section below.

For example, adding Algorand support:

```yaml
ledger_algorand: ^latest-version
```

### Setup

Create a new instance of `LedgerOptions` and pass it to the the `Ledger` constructor.

```dart
final options = LedgerOptions(
  maxScanDuration: const Duration(milliseconds: 5000),
);


final ledger = Ledger(
  options: options,
);
```

<details>
<summary>Android</summary>
</details>

<details>
<summary>iOS</summary>
</details>

### Ledger App Plugins

Each blockchain follows it own protocol which needs to be implemented before being able to get public keys & sign transactions.
We introduced the concept of Ledger App Plugins so any developer can easily create and integrate their own Ledger App Plugin and share it with the community.

We added the first support for the Algorand blockchain:

`pubspec.yaml`
```yaml
ledger_algorand: ^latest-version
```

```dart
final algorandApp = AlgorandLedgerApp(ledger);
final publicKeys = await algorandApp.getAccounts(device);
```

#### Existing plugins

- [Algorand](https://pub.dev/packages/ledger_algorand)
- [Create my own plugin]()

## Usage

### Scanning nearby devices

You can scan for nearby Ledger devices using the `scan()` method. This returns a `Stream` that can be listened to which emits when a new device has been found.

```dart
final subscription = ledger.scan().listen((device) => print(device));
```

Scanning stops once `maxScanDuration` is passed or the `stop()` method is called.
The `maxScanDuration` is the maximum amount of time BLE discovery should run in order to find nearby devices.


```dart
await ledger.stop();
```

#### Permissions

The Ledger Flutter plugin uses [Bluetooth Low Energy]() which requires certain permissions to be handled on both iOS & Android.
The plugin sends a callback every time a permission is required. All you have to do is override the `onPermissionRequest` and let the wonderful [permission_handler](https://pub.dev/packages/permission_handler) package handle the rest.

```dart
final ledger = Ledger(
  options: options,
  onPermissionRequest: (status) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    if (status != BleStatus.ready) {
      return false;
    }

    return statuses.values.where((status) => status.isDenied).isEmpty;
  },
);
```

### Connect to a Ledger device

Once a `LedgerDevice` has been found, you can easily connect to the device using the `connect()` method.

```dart
await ledger.connect(device);
```

A `LedgerException` is thrown if unable to connect to the device. 

The package also includes a `devices` stream which updates on connection changes.

```dart
final subscription = ledger.devices.listen((state) => print(state));
```

### Get public keys

Depending on the required blockchain and Ledger Application Plugin, the `getAccounts()` method can be used to fetch the public keys from the Ledger Nano device.


Depending on the implementation and supported protocol, there might be only once public key in the list of accounts.

```dart
final algorandApp = AlgorandLedgerApp(ledger);

final publicKeys = await algorandApp.getAccounts(device);
  accounts.addAll(publicKeys.map((pk) => Address.fromAlgorandAddress(pk)).toList(),
);
```

### Disconnect

Use the `disconnect()` method to close an established connection with a ledger device.

```dart
await ledger.disconnect(device);
```

### Dispose

Always use the `close()` method to close all connections and dispose any potential listeners to not leak any resources.

```dart
await ledger.close();
```

## Custom Ledger App Plugins

Each blockchain follows it own protocol which needs to be implemented before being able to get public keys & sign transactions.

- [Algorand](https://pub.dev/packages/ledger_algorand)
- [Create my own plugin]()


## Sponsors

Our top sponsors are shown below!

<table>
    <tbody>
        <tr>
            <td align="center" style="background-color: white">
                <a href="https://blockshake.io/"><img src="https://pbs.twimg.com/profile_images/1491803720593522691/7jXDOpGn_400x400.png" width="225"/></a>
            </td>
        </tr>
    </tbody>
</table>



## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag `enhancement`.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/my-feature`)
3. Commit your Changes (`git commit -m 'feat: my new feature`)
4. Push to the Branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Please try to follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## License

The ledger_flutter SDK is released under the Attribution Assurance License. See LICENSE for details.
