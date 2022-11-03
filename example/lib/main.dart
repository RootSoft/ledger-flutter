import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ledger_example/bloc/ledger_bloc.dart';
import 'package:ledger_example/channel/ledger_channel.dart';
import 'package:ledger_example/screens/ledger_ble_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LedgerBleApp());
}

class LedgerBleApp extends StatelessWidget {
  const LedgerBleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger Nano',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LedgerBleBloc(channel: LedgerChannel()),
          ),
        ],
        child: const LedgerBleScreen(),
      ),
    );
  }
}
