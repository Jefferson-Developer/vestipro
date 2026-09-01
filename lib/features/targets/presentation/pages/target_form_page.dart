import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/target.dart';
import '../../domain/value_objects/target_dimension_type.dart';
import '../../domain/value_objects/target_metric_type.dart';
import '../../domain/value_objects/target_period_granularity.dart';
import '../../domain/value_objects/target_status.dart';
import '../cubit/target_form_cubit.dart';
import '../cubit/target_form_state.dart';

/// Cadastro de metas (TASK-115, EPIC-15/VESTI-085): create/edit a [Target]
/// by dimensão (vendedor, equipe, empresa, coleção, categoria), período,
/// métrica, valor e moeda.
///
/// Gated behind [Capability.targetManage] the same way every other admin
/// cadastro page in this app is (`PromotionalCampaignsPage`,
/// `PaymentTermsPage`) — a `SALES_REP`, who never holds it, never even
/// reaches the form; `CreateTargetUseCase`/`UpdateTargetUseCase`
/// independently re-check the same capability server-side of this UI, so a
/// forged/stale client check here is never the real authorization boundary.
class TargetFormPage extends StatelessWidget {
  const TargetFormPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.actorName,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final PermissionService permissionService;
  final TargetFormCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.targetManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<TargetFormCubit>(
          create: (_) => createCubit()
            ..init(
              organizationId: organizationId,
              companyId: companyId,
              userId: userId,
              actorName: actorName,
            ),
          child: const _TargetFormView(),
        );
      },
    );
  }
}

class _TargetFormView extends StatefulWidget {
  const _TargetFormView();

  @override
  State<_TargetFormView> createState() => _TargetFormViewState();
}

class _TargetFormViewState extends State<_TargetFormView> {
  final _dimensionIdController = TextEditingController();
  final _targetValueController = TextEditingController();
  final _currencyController = TextEditingController(text: 'BRL');

  @override
  void dispose() {
    _dimensionIdController.dispose();
    _targetValueController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TargetFormCubit, TargetFormState>(
      listenWhen: (previous, current) =>
          previous.dimensionId != current.dimensionId ||
          previous.targetValueInput != current.targetValueInput ||
          previous.currency != current.currency ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        _sync(_dimensionIdController, state.dimensionId);
        _sync(_targetValueController, state.targetValueInput);
        _sync(_currencyController, state.currency);

        if (state.saveStatus == TargetFormSaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Meta salva com sucesso.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == TargetFormSaveStatus.failure &&
            state.failureMessage != null &&
            state.fieldErrors.isEmpty) {
          AppSnackbar.show(
            context,
            message: state.failureMessage!,
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.needsReduceConfirmation) {
          unawaited(_confirmReduceBelowAchieved(context, state));
        }
      },
      builder: (context, state) {
        _sync(_dimensionIdController, state.dimensionId);
        _sync(_targetValueController, state.targetValueInput);
        _sync(_currencyController, state.currency);
        final cubit = context.read<TargetFormCubit>();

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Cadastro de metas',
            actions: <Widget>[
              AppButton(
                label: state.isEditing ? 'Nova meta' : 'Limpar formulário',
                leadingIcon: Icons.flag_outlined,
                onPressed: state.isBusy ? null : cubit.startCreate,
              ),
            ],
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppDropdown<TargetDimensionType>(
                    options: const <AppDropdownOption<TargetDimensionType>>[
                      AppDropdownOption(
                        value: TargetDimensionType.salesRep,
                        label: 'Vendedor',
                      ),
                      AppDropdownOption(
                        value: TargetDimensionType.team,
                        label: 'Equipe',
                      ),
                      AppDropdownOption(
                        value: TargetDimensionType.company,
                        label: 'Empresa',
                      ),
                      AppDropdownOption(
                        value: TargetDimensionType.collection,
                        label: 'Coleção',
                      ),
                      AppDropdownOption(
                        value: TargetDimensionType.category,
                        label: 'Categoria',
                      ),
                    ],
                    selectedValues: <TargetDimensionType>{state.dimensionType},
                    isDisabled: state.isEditing,
                    onChanged: (values) =>
                        cubit.updateDraft(dimensionType: values.first),
                    closeSemanticLabel: 'Fechar seleção de dimensão',
                    label: 'Dimensão da meta',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          controller: _dimensionIdController,
                          label: _dimensionIdLabel(state.dimensionType),
                          semanticLabel: _dimensionIdLabel(state.dimensionType),
                          isRequired: true,
                          isDisabled: state.isEditing,
                          errorText: state.fieldErrors['dimensionId'],
                          onChanged: (value) =>
                              cubit.updateDraft(dimensionId: value),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      AppButton(
                        label: 'Buscar metas',
                        leadingIcon: Icons.search_outlined,
                        variant: AppButtonVariant.secondary,
                        isLoading:
                            state.loadStatus == TargetFormLoadStatus.loading,
                        onPressed: state.isBusy ? null : cubit.search,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppDropdown<TargetPeriodGranularity>(
                    options: const <AppDropdownOption<TargetPeriodGranularity>>[
                      AppDropdownOption(
                        value: TargetPeriodGranularity.monthly,
                        label: 'Mensal',
                      ),
                      AppDropdownOption(
                        value: TargetPeriodGranularity.quarterly,
                        label: 'Trimestral',
                      ),
                      AppDropdownOption(
                        value: TargetPeriodGranularity.yearly,
                        label: 'Anual',
                      ),
                    ],
                    selectedValues: <TargetPeriodGranularity>{
                      state.periodGranularity,
                    },
                    onChanged: (values) =>
                        cubit.updateDraft(periodGranularity: values.first),
                    closeSemanticLabel: 'Fechar seleção de período',
                    label: 'Cadência do período',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  _DateButtonRow(state: state, cubit: cubit),
                  for (final key in const <String>['startDate', 'endDate'])
                    if (state.fieldErrors[key] != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.spacing4),
                      Text(
                        state.fieldErrors[key]!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  const SizedBox(height: AppSpacing.spacing12),
                  AppDropdown<TargetMetricType>(
                    options: const <AppDropdownOption<TargetMetricType>>[
                      AppDropdownOption(
                        value: TargetMetricType.revenue,
                        label: 'Faturamento',
                      ),
                      AppDropdownOption(
                        value: TargetMetricType.quantity,
                        label: 'Quantidade',
                      ),
                      AppDropdownOption(
                        value: TargetMetricType.positivacao,
                        label: 'Positivação',
                      ),
                    ],
                    selectedValues: <TargetMetricType>{state.metricType},
                    onChanged: (values) =>
                        cubit.updateDraft(metricType: values.first),
                    closeSemanticLabel: 'Fechar seleção de métrica',
                    label: 'Métrica',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          controller: _targetValueController,
                          label: 'Valor da meta',
                          semanticLabel: 'Valor da meta',
                          isRequired: true,
                          errorText: state.fieldErrors['targetValue'],
                          onChanged: (value) =>
                              cubit.updateDraft(targetValueInput: value),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        child: AppTextField(
                          controller: _currencyController,
                          label: 'Moeda',
                          semanticLabel: 'Moeda da meta',
                          isRequired: true,
                          errorText: state.fieldErrors['currency'],
                          onChanged: (value) =>
                              cubit.updateDraft(currency: value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppDropdown<TargetStatus>(
                    options: const <AppDropdownOption<TargetStatus>>[
                      AppDropdownOption(
                        value: TargetStatus.draft,
                        label: 'Rascunho',
                      ),
                      AppDropdownOption(
                        value: TargetStatus.active,
                        label: 'Ativa',
                      ),
                      AppDropdownOption(
                        value: TargetStatus.closed,
                        label: 'Encerrada',
                      ),
                    ],
                    selectedValues: <TargetStatus>{state.status},
                    onChanged: (values) =>
                        cubit.updateDraft(status: values.first),
                    closeSemanticLabel: 'Fechar seleção de status',
                    label: 'Status',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: state.isEditing
                          ? 'Salvar alterações'
                          : 'Criar meta',
                      leadingIcon: Icons.save_outlined,
                      isLoading:
                          state.saveStatus == TargetFormSaveStatus.submitting,
                      onPressed: state.isBusy ? null : () => cubit.submit(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing24),
                  SizedBox(
                    height: 420,
                    child: _TargetTable(state: state, cubit: cubit),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReduceBelowAchieved(
    BuildContext context,
    TargetFormState state,
  ) async {
    final cubit = context.read<TargetFormCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reduzir valor abaixo do realizado?'),
        content: Text(
          state.failureMessage ??
              'O novo valor da meta é menor do que o já realizado.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar mesmo assim'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.submit(confirmReduceBelowAchieved: true);
    }
  }

  String _dimensionIdLabel(TargetDimensionType dimensionType) {
    return switch (dimensionType) {
      TargetDimensionType.salesRep => 'Id do vendedor',
      TargetDimensionType.team => 'Id da equipe',
      TargetDimensionType.company => 'Id da empresa',
      TargetDimensionType.collection => 'Id da coleção',
      TargetDimensionType.category => 'Id da categoria',
    };
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }
}

class _DateButtonRow extends StatelessWidget {
  const _DateButtonRow({required this.state, required this.cubit});

  final TargetFormState state;
  final TargetFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Início: ${_label(state.startDate)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final picked = await _pickDate(context, state.startDate);
              if (picked != null) cubit.updateDraft(startDate: picked);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: AppButton(
            label: 'Fim: ${_label(state.endDate)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final picked = await _pickDate(context, state.endDate);
              if (picked != null) cubit.updateDraft(endDate: picked);
            },
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final base = initial ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 3),
      lastDate: DateTime(base.year + 5),
    );
  }

  String _label(DateTime? date) {
    if (date == null) return 'sem data';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _TargetTable extends StatelessWidget {
  const _TargetTable({required this.state, required this.cubit});

  final TargetFormState state;
  final TargetFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == TargetFormLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == TargetFormLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar as metas',
        message: state.failureMessage ?? 'Tente novamente em breve.',
      );
    }
    if (state.targets.isEmpty) {
      return const AppEmptyState(
        icon: Icons.flag_outlined,
        title: 'Nenhuma meta encontrada',
        description:
            'Informe a dimensão e busque para ver as metas já cadastradas, '
            'ou crie uma nova meta acima.',
      );
    }

    return SingleChildScrollView(
      child: AppDataTable<Target>(
        status: AppDataTableStatus.idle,
        rows: state.targets,
        rowIdBuilder: (item) => item.id,
        mobileCardTitleBuilder: (context, item) => Text(item.metricType.name),
        columns: <AppDataColumn<Target>>[
          AppDataColumn(
            label: 'Período',
            cellBuilder: (context, item) => Text(
              '${_shortDate(item.startDate)} - ${_shortDate(item.endDate)}',
            ),
          ),
          AppDataColumn(
            label: 'Métrica',
            cellBuilder: (context, item) => Text(item.metricType.name),
          ),
          AppDataColumn(
            label: 'Valor',
            cellBuilder: (context, item) =>
                Text('${item.currency} ${item.targetValue.toStringAsFixed(2)}'),
          ),
          AppDataColumn(
            label: 'Status',
            cellBuilder: (context, item) => Text(item.status.name),
          ),
        ],
        rowActions: <AppDataTableAction<Target>>[
          AppDataTableAction<Target>(
            icon: Icons.edit_outlined,
            semanticLabel: 'Editar meta',
            onPressed: cubit.startEdit,
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
