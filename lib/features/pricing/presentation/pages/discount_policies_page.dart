import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/discount_policy.dart';
import '../../domain/value_objects/discount_policy_status.dart';
import '../cubit/discount_policy_cubit.dart';
import '../cubit/discount_policy_state.dart';

class DiscountPoliciesPage extends StatelessWidget {
  const DiscountPoliciesPage({
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
  final DiscountPolicyCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.priceListManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<DiscountPolicyCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
                actorName: actorName,
              ),
            );
            return cubit;
          },
          child: const _DiscountPoliciesView(),
        );
      },
    );
  }
}

class _DiscountPoliciesView extends StatefulWidget {
  const _DiscountPoliciesView();

  @override
  State<_DiscountPoliciesView> createState() => _DiscountPoliciesViewState();
}

class _DiscountPoliciesViewState extends State<_DiscountPoliciesView> {
  final _roleController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _approvalThresholdController = TextEditingController();
  final _priceListIdsController = TextEditingController();

  @override
  void dispose() {
    _roleController.dispose();
    _maxDiscountController.dispose();
    _approvalThresholdController.dispose();
    _priceListIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DiscountPolicyCubit, DiscountPolicyState>(
      listenWhen: (previous, current) =>
          previous.role != current.role ||
          previous.maxDiscountPercentInput != current.maxDiscountPercentInput ||
          previous.requiresApprovalAbovePercentInput !=
              current.requiresApprovalAbovePercentInput ||
          previous.priceListIdsInput != current.priceListIdsInput ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        _sync(_roleController, state.role);
        _sync(_maxDiscountController, state.maxDiscountPercentInput);
        _sync(
          _approvalThresholdController,
          state.requiresApprovalAbovePercentInput,
        );
        _sync(_priceListIdsController, state.priceListIdsInput);
        if (state.saveStatus == DiscountPolicySaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Política de desconto salva.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == DiscountPolicySaveStatus.failure &&
            state.failureMessage != null &&
            state.fieldErrors.isEmpty) {
          AppSnackbar.show(
            context,
            message: state.failureMessage!,
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        _sync(_roleController, state.role);
        _sync(_maxDiscountController, state.maxDiscountPercentInput);
        _sync(
          _approvalThresholdController,
          state.requiresApprovalAbovePercentInput,
        );
        _sync(_priceListIdsController, state.priceListIdsInput);
        final cubit = context.read<DiscountPolicyCubit>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Políticas de desconto por perfil',
            actions: <Widget>[
              AppButton(
                label: state.isEditing ? 'Nova política' : 'Limpar formulário',
                leadingIcon: Icons.discount_outlined,
                onPressed: state.isBusy ? null : cubit.startCreate,
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _roleController,
                  label: 'Perfil',
                  semanticLabel: 'Perfil da política de desconto',
                  hintText: 'SALES_REP',
                  isRequired: true,
                  errorText: state.fieldErrors['role'],
                  onChanged: (value) => cubit.updateDraft(role: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _maxDiscountController,
                  label: 'Limite máximo de desconto (%)',
                  semanticLabel: 'Limite máximo de desconto',
                  hintText: '15',
                  isRequired: true,
                  errorText: state.fieldErrors['maxDiscountPercent'],
                  onChanged: (value) =>
                      cubit.updateDraft(maxDiscountPercentInput: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _approvalThresholdController,
                  label: 'Exigir aprovação acima de (%)',
                  semanticLabel: 'Gatilho de aprovação do desconto',
                  hintText: '10',
                  errorText: state.fieldErrors['requiresApprovalAbovePercent'],
                  onChanged: (value) => cubit.updateDraft(
                    requiresApprovalAbovePercentInput: value,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _priceListIdsController,
                  label: 'Tabelas de preço permitidas',
                  semanticLabel: 'Escopo por tabelas de preço',
                  hintText: 'varejo, atacado-premium',
                  errorText: state.fieldErrors['priceListIds'],
                  onChanged: (value) =>
                      cubit.updateDraft(priceListIdsInput: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppDropdown<DiscountPolicyStatus>(
                  options: const <AppDropdownOption<DiscountPolicyStatus>>[
                    AppDropdownOption(
                      value: DiscountPolicyStatus.active,
                      label: 'Ativa',
                    ),
                    AppDropdownOption(
                      value: DiscountPolicyStatus.inactive,
                      label: 'Inativa',
                    ),
                  ],
                  selectedValues: <DiscountPolicyStatus>{state.status},
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
                        : 'Criar política',
                    leadingIcon: Icons.save_outlined,
                    isLoading: state.isBusy,
                    onPressed: state.isBusy ? null : cubit.submit,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                Expanded(
                  child: _PoliciesTable(state: state, cubit: cubit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }
}

class _PoliciesTable extends StatelessWidget {
  const _PoliciesTable({required this.state, required this.cubit});

  final DiscountPolicyState state;
  final DiscountPolicyCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == DiscountPolicyLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == DiscountPolicyLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar as políticas',
        message: state.failureMessage ?? 'Tente novamente em breve.',
      );
    }
    if (state.policies.isEmpty) {
      return const AppEmptyState(
        icon: Icons.percent_outlined,
        title: 'Nenhuma política cadastrada',
        description:
            'Cadastre limites por perfil para bloquear descontos fora da governança comercial.',
      );
    }

    return SingleChildScrollView(
      child: AppDataTable<DiscountPolicy>(
        status: AppDataTableStatus.idle,
        rows: state.policies,
        rowIdBuilder: (item) => item.id,
        mobileCardTitleBuilder: (context, item) => Text(item.role),
        columns: <AppDataColumn<DiscountPolicy>>[
          AppDataColumn(
            label: 'Perfil',
            cellBuilder: (context, item) => Text(item.role),
          ),
          AppDataColumn(
            label: 'Limite máximo',
            cellBuilder: (context, item) =>
                Text('${item.maxDiscountPercent.toStringAsFixed(0)}%'),
          ),
          AppDataColumn(
            label: 'Aprovação acima de',
            cellBuilder: (context, item) =>
                Text('${item.approvalThresholdPercent.toStringAsFixed(0)}%'),
          ),
          AppDataColumn(
            label: 'Escopo',
            cellBuilder: (context, item) => Text(
              item.priceListIds.isEmpty
                  ? 'Todas as tabelas'
                  : item.priceListIds.join(', '),
            ),
          ),
          AppDataColumn(
            label: 'Status',
            cellBuilder: (context, item) => Text(
              item.status == DiscountPolicyStatus.active ? 'Ativa' : 'Inativa',
            ),
          ),
        ],
        rowActions: <AppDataTableAction<DiscountPolicy>>[
          AppDataTableAction<DiscountPolicy>(
            icon: Icons.edit_outlined,
            semanticLabel: 'Editar política',
            onPressed: cubit.startEdit,
          ),
        ],
      ),
    );
  }
}
