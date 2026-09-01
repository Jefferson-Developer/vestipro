import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/positivacao_snapshot.dart';
import '../../domain/value_objects/positivacao_dimension_type.dart';
import '../cubit/positivacao_dashboard_cubit.dart';
import '../cubit/positivacao_dashboard_state.dart';

final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

/// Dashboard de positivação de carteira (TASK-117, EPIC-15/VESTI-087):
/// quantos clientes da carteira compraram no período corrente, com a lista
/// de clientes pendentes de compra para ação comercial.
///
/// Gated behind [Capability.targetView] — the same capability
/// `TargetDashboardPage` (TASK-116) uses, since positivação is tracked as
/// one more `TargetMetricType` a caller who can see achievement dashboards
/// is already trusted to see; which dimension the caller may then actually
/// see is `TargetVisibilityFilter`'s job (`PositivacaoDashboardCubit`,
/// reusing `TargetVisibilityService`), never re-implemented here.
class PositivacaoDashboardPage extends StatelessWidget {
  const PositivacaoDashboardPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final PositivacaoDashboardCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.targetView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<PositivacaoDashboardCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            );
            return cubit;
          },
          child: const _PositivacaoDashboardView(),
        );
      },
    );
  }
}

class _PositivacaoDashboardView extends StatefulWidget {
  const _PositivacaoDashboardView();

  @override
  State<_PositivacaoDashboardView> createState() =>
      _PositivacaoDashboardViewState();
}

class _PositivacaoDashboardViewState extends State<_PositivacaoDashboardView> {
  final _dimensionIdController = TextEditingController();

  @override
  void dispose() {
    _dimensionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PositivacaoDashboardCubit, PositivacaoDashboardState>(
      builder: (context, state) {
        if (_dimensionIdController.text != state.dimensionId) {
          _dimensionIdController.text = state.dimensionId;
        }
        final cubit = context.read<PositivacaoDashboardCubit>();

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Positivação de carteira',
            filtersBuilder: (context) => _PositivacaoDashboardFilters(
              state: state,
              cubit: cubit,
              dimensionIdController: _dimensionIdController,
            ),
            content: _PositivacaoDashboardContent(state: state),
          ),
        );
      },
    );
  }
}

class _PositivacaoDashboardFilters extends StatelessWidget {
  const _PositivacaoDashboardFilters({
    required this.state,
    required this.cubit,
    required this.dimensionIdController,
  });

  final PositivacaoDashboardState state;
  final PositivacaoDashboardCubit cubit;
  final TextEditingController dimensionIdController;

  @override
  Widget build(BuildContext context) {
    if (!state.canPickDimension) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDropdown<PositivacaoDimensionType>(
          options: const <AppDropdownOption<PositivacaoDimensionType>>[
            AppDropdownOption(
              value: PositivacaoDimensionType.salesRep,
              label: 'Vendedor',
            ),
            AppDropdownOption(
              value: PositivacaoDimensionType.team,
              label: 'Equipe',
            ),
            AppDropdownOption(
              value: PositivacaoDimensionType.company,
              label: 'Empresa',
            ),
          ],
          selectedValues: <PositivacaoDimensionType>{state.dimensionType},
          onChanged: (values) => cubit.selectDimension(
            dimensionType: values.first,
            dimensionId: state.dimensionId,
          ),
          closeSemanticLabel: 'Fechar seleção de dimensão',
          label: 'Dimensão',
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppTextField(
          controller: dimensionIdController,
          label: _dimensionIdLabel(state.dimensionType),
          semanticLabel: _dimensionIdLabel(state.dimensionType),
          onChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.spacing8),
        AppButton(
          label: 'Ver positivação',
          variant: AppButtonVariant.secondary,
          isLoading: state.isBusy,
          onPressed: state.isBusy
              ? null
              : () => cubit.selectDimension(
                  dimensionType: state.dimensionType,
                  dimensionId: dimensionIdController.text,
                ),
        ),
      ],
    );
  }

  String _dimensionIdLabel(PositivacaoDimensionType dimensionType) {
    return switch (dimensionType) {
      PositivacaoDimensionType.salesRep => 'Id do vendedor',
      PositivacaoDimensionType.team => 'Id da equipe',
      PositivacaoDimensionType.company => 'Id da empresa',
    };
  }
}

class _PositivacaoDashboardContent extends StatelessWidget {
  const _PositivacaoDashboardContent({required this.state});

  final PositivacaoDashboardState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case PositivacaoDashboardStatus.initial:
      case PositivacaoDashboardStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PositivacaoDashboardStatus.forbidden:
        return const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Sem acesso a esta carteira',
          description:
              'Você não tem permissão para ver a positivação desta '
              'carteira. Fale com seu gestor caso acredite que isso é um '
              'engano.',
        );
      case PositivacaoDashboardStatus.error:
        return AppErrorState(
          title: 'Não foi possível carregar a positivação',
          message: state.failureMessage ?? 'Tente novamente em breve.',
        );
      case PositivacaoDashboardStatus.emptyPortfolio:
        return const AppEmptyState(
          icon: Icons.groups_outlined,
          title: 'Carteira sem clientes',
          description:
              'Esta carteira não possui clientes cadastrados no período — '
              'não há o que positivar ainda.',
        );
      case PositivacaoDashboardStatus.notCalculated:
      case PositivacaoDashboardStatus.ready:
        return _PositivacaoDashboardBody(state: state);
    }
  }
}

class _PositivacaoDashboardBody extends StatelessWidget {
  const _PositivacaoDashboardBody({required this.state});

  final PositivacaoDashboardState state;

  @override
  Widget build(BuildContext context) {
    final period = state.period;
    if (period == null) {
      return const AppEmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'Selecione uma carteira',
        description: 'Escolha uma dimensão nos filtros para ver a positivação.',
      );
    }
    final snapshot = state.snapshot;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Período de referência: ${_dateFormat.format(period.start)} a '
            '${_dateFormat.format(period.end.subtract(const Duration(days: 1)))}',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            snapshot?.calculatedAt != null
                ? 'Último cálculo: '
                      '${_dateTimeFormat.format(snapshot!.calculatedAt!.toLocal())}'
                : 'Cálculo da positivação ainda não disponível para este '
                      'período — os valores abaixo podem estar desatualizados '
                      'ou zerados até a próxima sincronização.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Wrap(
            spacing: AppSpacing.spacing16,
            runSpacing: AppSpacing.spacing16,
            children: _kpiCards(snapshot),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Clientes pendentes de compra no período',
            style: AppTypography.labelLarge,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _PendingCustomersList(state: state),
        ],
      ),
    );
  }

  List<Widget> _kpiCards(PositivacaoSnapshot? snapshot) {
    return <Widget>[
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Carteira total',
          value: '${snapshot?.totalPortfolio ?? 0}',
          icon: Icons.groups_outlined,
        ),
      ),
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: 'Clientes positivados',
          value: '${snapshot?.positivatedCount ?? 0}',
          icon: Icons.check_circle_outline,
        ),
      ),
      SizedBox(
        width: 240,
        child: AppKpiCard(
          label: '% Positivação',
          value: '${(snapshot?.percentage ?? 0).toStringAsFixed(1)}%',
          icon: Icons.percent_outlined,
        ),
      ),
    ];
  }
}

class _PendingCustomersList extends StatelessWidget {
  const _PendingCustomersList({required this.state});

  final PositivacaoDashboardState state;

  @override
  Widget build(BuildContext context) {
    final snapshot = state.snapshot;
    final pendingIds = snapshot?.nonPositivatedCustomerIds ?? const <String>[];
    if (pendingIds.isEmpty) {
      return const AppEmptyState(
        icon: Icons.celebration_outlined,
        title: 'Nenhum cliente pendente',
        description:
            'Todos os clientes desta carteira já compraram no período — ou '
            'o cálculo ainda não está disponível.',
      );
    }

    return SizedBox(
      height: 360,
      child: AppDataTable<String>(
        status: AppDataTableStatus.idle,
        rows: pendingIds,
        rowIdBuilder: (customerId) => customerId,
        mobileCardTitleBuilder: (context, customerId) =>
            Text(state.pendingCustomerLabels[customerId] ?? customerId),
        columns: <AppDataColumn<String>>[
          AppDataColumn(
            label: 'Cliente',
            cellBuilder: (context, customerId) =>
                Text(state.pendingCustomerLabels[customerId] ?? customerId),
          ),
        ],
      ),
    );
  }
}
