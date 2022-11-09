import 'package:algorand_dart/algorand_dart.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ledger_example/bloc/ledger_bloc.dart';
import 'package:ledger_example/bloc/ledger_event.dart';
import 'package:ledger_example/bloc/ledger_state.dart';
import 'package:ledger_example/utils/toast.dart';
import 'package:ledger_example/widgets/account_list_tile.dart';
import 'package:ledger_example/widgets/ledger_list_tile.dart';

class LedgerBleScreen extends StatelessWidget {
  const LedgerBleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ledger Nano X'),
      ),
      body: const LedgerBleView(),
    );
  }
}

class LedgerBleView extends StatefulWidget {
  const LedgerBleView({Key? key}) : super(key: key);

  @override
  State<LedgerBleView> createState() => _LedgerBleViewState();
}

class _LedgerBleViewState extends State<LedgerBleView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerBleBloc>().state;

    return MultiBlocListener(
      listeners: [
        BlocListener<LedgerBleBloc, LedgerBleState>(
          listener: (_, state) {
            if (state.status == LedgerBleStatus.failure) {
              'Please open the Algorand App on your ledger device.'
                  .toast(context);
            }
          },
        ),
      ],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  context.read<LedgerBleBloc>().add(LedgerBleScanStarted());
                },
                child: Text('Scan for Ledger devices'),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.devices.length,
                shrinkWrap: true,
                itemBuilder: (_, index) => LedgerListTile(
                  ledger: state.devices[index],
                  onTap: (ledger) {
                    context
                        .read<LedgerBleBloc>()
                        .add(LedgerBleConnectRequested(ledger));
                  },
                ),
              ),
              TextButton(
                onPressed:
                    state.status == LedgerBleStatus.scanning ? () {} : null,
                child: Text('Stop scanning'),
              ),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.accounts.length,
                shrinkWrap: true,
                itemBuilder: (_, index) => AccountListTile(
                  address: state.accounts[index],
                  onTap: (account) {},
                ),
              ),
              TextButton(
                onPressed: state.status == LedgerBleStatus.connected
                    ? () async {
                        final device = state.device;
                        final account = state.accounts.firstOrNull;
                        if (device == null || account == null) {
                          return;
                        }

                        final tx = await _buildTransaction(address: account);

                        context
                            .read<LedgerBleBloc>()
                            .add(LedgerBleSignTransactionRequested(device, tx));
                      }
                    : null,
                child: Text('Sign transaction'),
              ),
              TextButton(
                onPressed: state.status == LedgerBleStatus.connected
                    ? () {
                        final device = state.device;
                        if (device == null) {
                          return;
                        }

                        context
                            .read<LedgerBleBloc>()
                            .add(LedgerBleDisconnectRequested(device));
                      }
                    : null,
                child: Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<RawTransaction> _buildTransaction({required Address address}) async {
    final channel = context.read<LedgerBleBloc>().channel;

    final tx = await channel.algorand.createPaymentTransaction(
      sender: address,
      receiver: address,
      amount: Algo.toMicroAlgos(1),
    );

    return tx;
  }
}
