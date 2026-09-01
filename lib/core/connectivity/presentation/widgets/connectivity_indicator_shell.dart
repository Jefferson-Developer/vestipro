import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../../navigation/app_route_paths.dart';
import '../cubit/connectivity_indicator_cubit.dart';
import '../cubit/connectivity_indicator_state.dart';

/// Reusable authenticated-page wrapper that keeps TASK-113's connectivity
/// indicator visible above the routed child, without each feature having to
/// manage connectivity subscriptions or duplicate the same banner UI.
class ConnectivityIndicatorShell extends StatefulWidget {
  const ConnectivityIndicatorShell({
    required this.organizationId,
    required this.companyId,
    required this.createCubit,
    required this.child,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final ConnectivityIndicatorCubit Function() createCubit;
  final Widget child;

  @override
  State<ConnectivityIndicatorShell> createState() =>
      _ConnectivityIndicatorShellState();
}

class _ConnectivityIndicatorShellState
    extends State<ConnectivityIndicatorShell> {
  late final ConnectivityIndicatorCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.createCubit();
    unawaited(_cubit.watch(organizationId: widget.organizationId));
  }

  @override
  void dispose() {
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConnectivityIndicatorCubit>.value(
      value: _cubit,
      child: Column(
        children: <Widget>[
          BlocBuilder<ConnectivityIndicatorCubit, ConnectivityIndicatorState>(
            builder: (context, state) => AppConnectivityIndicator(
              status: state.status,
              outboxSummary: state.outboxSummary,
              onTap: () => context.go(
                SyncCenterRoute(
                  orgId: widget.organizationId,
                  companyId: widget.companyId,
                ).location,
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
