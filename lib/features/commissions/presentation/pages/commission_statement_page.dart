import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/commission_entry.dart';
import '../cubit/commission_statement_cubit.dart';
import '../cubit/commission_statement_state.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');

String _money(double value, String currency) =>
    CurrencyFormatter.formatWithCode(value, currency);

class CommissionStatementPage extends StatelessWidget {
  const CommissionStatementPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    this.managementMode = false,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final CommissionStatementCubit Function() createCubit;
  final bool managementMode;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: managementMode
          ? Capability.financeView
          : Capability.reportShareTeam,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CommissionStatementCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
                sellerId: managementMode ? null : userId,
              ),
            );
            return cubit;
          },
          child: _CommissionStatementView(managementMode: managementMode),
        );
      },
    );
  }
}

class _CommissionStatementView extends StatelessWidget {
  const _CommissionStatementView({required this.managementMode});

  final bool managementMode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommissionStatementCubit, CommissionStatementState>(
      builder: (context, state) => Scaffold(
        body: AppAdminPageLayout(
          title: managementMode
              ? 'Conciliação de comissões'
              : 'Meu extrato de comissões',
          filtersBuilder: (context) => _CommissionFilters(state: state),
          content: _CommissionContent(
            state: state,
            managementMode: managementMode,
          ),
        ),
      ),
    );
  }
}

class _CommissionFilters extends StatelessWidget {
  const _CommissionFilters({required this.state});

  final CommissionStatementState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<CommissionEntryStatus?>(
          initialValue: state.statusFilter,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Todos')),
            DropdownMenuItem(
              value: CommissionEntryStatus.provisioned,
              child: Text('Provisionadas'),
            ),
            DropdownMenuItem(
              value: CommissionEntryStatus.approved,
              child: Text('Aprovadas'),
            ),
            DropdownMenuItem(
              value: CommissionEntryStatus.paid,
              child: Text('Pagas'),
            ),
            DropdownMenuItem(
              value: CommissionEntryStatus.reversed,
              child: Text('Estornadas'),
            ),
          ],
          onChanged: (value) {
            final cubit = context.read<CommissionStatementCubit>();
            unawaited(
              cubit.filter(
                organizationId: state.organizationId,
                companyId: state.companyId,
                userId: state.userId,
                from: state.from ?? DateTime.now(),
                to: state.to ?? DateTime.now().add(const Duration(days: 31)),
                sellerId: state.sellerId,
                status: value,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CommissionContent extends StatelessWidget {
  const _CommissionContent({required this.state, required this.managementMode});

  final CommissionStatementState state;
  final bool managementMode;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CommissionStatementStatus.initial:
      case CommissionStatementStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CommissionStatementStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar as comissões',
          message: state.failureMessage ?? 'Tente novamente em instantes.',
        );
      case CommissionStatementStatus.empty:
        return const AppEmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Nenhum lançamento no período',
          description:
              'Quando pedidos forem faturados ou estornados, os lançamentos aparecerão aqui.',
        );
      case CommissionStatementStatus.ready:
        return _CommissionTable(state: state, managementMode: managementMode);
    }
  }
}

class _CommissionTable extends StatelessWidget {
  const _CommissionTable({required this.state, required this.managementMode});

  final CommissionStatementState state;
  final bool managementMode;

  @override
  Widget build(BuildContext context) {
    final currency = state.entries.firstOrNull?.currency ?? 'BRL';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.spacing12,
            runSpacing: AppSpacing.spacing12,
            children: [
              AppKpiCard(
                label: 'Provisionado',
                value: _money(state.provisionedTotal, currency),
                icon: Icons.pending_actions_outlined,
              ),
              AppKpiCard(
                label: 'Aprovado/pago',
                value: _money(state.payableTotal, currency),
                icon: Icons.verified_outlined,
              ),
              AppKpiCard(
                label: 'Estornos',
                value: _money(state.reversalTotal, currency),
                icon: Icons.undo_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing24),
          AppDataTable<CommissionEntry>(
            status: AppDataTableStatus.idle,
            rows: state.entries,
            rowIdBuilder: (entry) => entry.id,
            columns: [
              AppDataColumn(
                label: 'Pedido',
                cellBuilder: (context, entry) =>
                    Text(entry.orderNumber ?? entry.orderId),
              ),
              if (managementMode)
                AppDataColumn(
                  label: 'Vendedor',
                  cellBuilder: (context, entry) => Text(entry.sellerLabel),
                ),
              AppDataColumn(
                label: 'Data',
                cellBuilder: (context, entry) =>
                    Text(_dateFormat.format(entry.occurredAt)),
              ),
              AppDataColumn(
                label: 'Base',
                numeric: true,
                cellBuilder: (context, entry) =>
                    Text(_money(entry.baseAmount, entry.currency)),
              ),
              AppDataColumn(
                label: 'Comissão',
                numeric: true,
                cellBuilder: (context, entry) =>
                    Text(_money(entry.commissionAmount, entry.currency)),
              ),
              AppDataColumn(
                label: 'Regra',
                cellBuilder: (context, entry) =>
                    Text(entry.ruleId ?? 'Estorno'),
              ),
              AppDataColumn(
                label: 'Status',
                cellBuilder: (context, entry) => AppStatusBadge(
                  label: _statusLabel(entry.status),
                  variant: entry.isReversal
                      ? AppStatusBadgeVariant.warning
                      : AppStatusBadgeVariant.info,
                ),
              ),
            ],
            mobileCardTitleBuilder: (context, entry) =>
                Text(entry.orderNumber ?? entry.orderId),
          ),
        ],
      ),
    );
  }

  String _statusLabel(CommissionEntryStatus status) => switch (status) {
    CommissionEntryStatus.provisioned => 'Provisionada',
    CommissionEntryStatus.approved => 'Aprovada',
    CommissionEntryStatus.paid => 'Paga',
    CommissionEntryStatus.reversed => 'Estornada',
  };
}
