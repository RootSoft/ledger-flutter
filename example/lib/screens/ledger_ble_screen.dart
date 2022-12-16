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
        title: const Text('Ledger Nano X'),
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
                child: const Text('Scan for Ledger devices'),
              ),
              TextButton(
                onPressed: () {
                  context.read<LedgerBleBloc>().add(LedgerBleUsbStarted());
                },
                child: const Text('List USB devices'),
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
                child: const Text('Stop scanning'),
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

                        context
                            .read<LedgerBleBloc>()
                            .add(LedgerBleSignTransactionRequested(
                              device,
                              account,
                            ));
                      }
                    : null,
                child: const Text('Sign transaction'),
              ),
              if (state.signature != null) ...[
                Text(state.signature ?? ''),
              ],
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
                child: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
