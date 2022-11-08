import 'package:flutter/material.dart';

extension Toast on String {
  Future toast(
    BuildContext context, {
    Duration duration = const Duration(seconds: 3),
    Color? color,
  }) async {
    final scaffold = ScaffoldMessenger.of(context);
    final controller = scaffold.showSnackBar(
      SnackBar(
        content: Text(this),
        backgroundColor: color ?? Colors.red.shade300,
        behavior: SnackBarBehavior.floating,
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );

    await Future.delayed(duration);
    controller.close();
  }
}
