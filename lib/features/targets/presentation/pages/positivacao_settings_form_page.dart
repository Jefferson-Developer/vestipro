import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../orders/orders.dart';
import '../cubit/positivacao_settings_cubit.dart';
import '../cubit/positivacao_settings_state.dart';

/// Admin screen for the organization-configurable positivação rule
/// (TASK-117, EPIC-15/VESTI-087): which period cadence, which `OrderStatus`
/// codes and which minimum order value make a customer count as
/// "positivado" — never hardcoded, so each organization/brand tunes its own
/// rule.
///
/// Gated behind [Capability.organizationSettingsManage] — the same
/// capability that already governs the rest of `OrganizationSettings`
/// (currency, required customer fields, etc.), only ever granted to
/// OWNER/ADMIN.
class PositivacaoSettingsFormPage extends StatelessWidget {
  const PositivacaoSettingsFormPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final PositivacaoSettingsCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.organizationSettingsManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<PositivacaoSettingsCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(organizationId: organizationId, updatedBy: userId),
            );
            return cubit;
          },
          child: const _PositivacaoSettingsFormView(),
        );
      },
    );
  }
}

class _PositivacaoSettingsFormView extends StatefulWidget {
  const _PositivacaoSettingsFormView();

  @override
  State<_PositivacaoSettingsFormView> createState() =>
      _PositivacaoSettingsFormViewState();
}

class _PositivacaoSettingsFormViewState
    extends State<_PositivacaoSettingsFormView> {
  final _minOrderValueController = TextEditingController();

  @override
  void dispose() {
    _minOrderValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PositivacaoSettingsCubit, PositivacaoSettingsState>(
      listenWhen: (previous, current) =>
          previous.minOrderValueInput != current.minOrderValueInput ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        if (_minOrderValueController.text != state.minOrderValueInput) {
          _minOrderValueController.text = state.minOrderValueInput;
        }
        if (state.saveStatus == PositivacaoSettingsSaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Regra de positivação salva com sucesso.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == PositivacaoSettingsSaveStatus.failure &&
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
        if (_minOrderValueController.text != state.minOrderValueInput) {
          _minOrderValueController.text = state.minOrderValueInput;
        }
        final cubit = context.read<PositivacaoSettingsCubit>();

        if (state.loadStatus == PositivacaoSettingsLoadStatus.loading ||
            state.loadStatus == PositivacaoSettingsLoadStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.loadStatus == PositivacaoSettingsLoadStatus.failure) {
          return Scaffold(
            body: AppErrorState(
              title: 'Não foi possível carregar a configuração',
              message: state.failureMessage ?? 'Tente novamente em breve.',
            ),
          );
        }

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Regra de positivação de carteira',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Define quais pedidos contam como "cliente positivado" '
                    'nesta organização, alimentando o dashboard de '
                    'positivação de carteira.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppDropdown<String>(
                    options: const <AppDropdownOption<String>>[
                      AppDropdownOption(value: 'monthly', label: 'Mensal'),
                      AppDropdownOption(
                        value: 'quarterly',
                        label: 'Trimestral',
                      ),
                      AppDropdownOption(value: 'yearly', label: 'Anual'),
                    ],
                    selectedValues: <String>{state.periodGranularity},
                    onChanged: (values) =>
                        cubit.updateDraft(periodGranularity: values.first),
                    closeSemanticLabel: 'Fechar seleção de período',
                    label: 'Cadência do período',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppDropdown<OrderStatus>(
                    multiple: true,
                    options: <AppDropdownOption<OrderStatus>>[
                      for (final status in OrderStatus.values)
                        AppDropdownOption(
                          value: status,
                          label: orderStatusLabel(status),
                        ),
                    ],
                    selectedValues: state.eligibleOrderStatuses
                        .map(
                          (code) => OrderStatus.values.firstWhere(
                            (status) => status.name == code,
                          ),
                        )
                        .toSet(),
                    onChanged: (values) => cubit.updateDraft(
                      eligibleOrderStatuses: values
                          .map((status) => status.name)
                          .toSet(),
                    ),
                    closeSemanticLabel: 'Fechar seleção de status',
                    label: 'Status de pedido elegíveis',
                  ),
                  if (state.fieldErrors['positivacaoEligibleOrderStatuses'] !=
                      null) ...<Widget>[
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      state.fieldErrors['positivacaoEligibleOrderStatuses']!,
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spacing12),
                  AppTextField(
                    controller: _minOrderValueController,
                    label: 'Valor mínimo do pedido (opcional)',
                    semanticLabel: 'Valor mínimo do pedido',
                    errorText: state.fieldErrors['minOrderValue'],
                    onChanged: (value) =>
                        cubit.updateDraft(minOrderValueInput: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: 'Salvar regra',
                      leadingIcon: Icons.save_outlined,
                      isLoading:
                          state.saveStatus ==
                          PositivacaoSettingsSaveStatus.submitting,
                      onPressed: state.isBusy ? null : cubit.submit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
