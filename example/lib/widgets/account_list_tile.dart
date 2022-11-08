import 'package:algorand_dart/algorand_dart.dart';
import 'package:flutter/material.dart';

typedef AccountGestureCallback = void Function(Address address);

class AccountListTile extends StatelessWidget {
  final Address address;
  final AccountGestureCallback? onTap;

  const AccountListTile({
    required this.address,
    this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(address.encodedAddress),
      onTap: () {
        onTap?.call(address);
      },
    );
  }
}
