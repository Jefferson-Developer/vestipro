import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/customer_credit_profile.dart';
import '../../domain/value_objects/credit_block_policy.dart';
import '../../domain/value_objects/credit_status.dart';
import '../bloc/customer_credit_cubit.dart';
import '../bloc/customer_credit_state.dart';

/// Customer 360º's credit section (TASK-212) — lives inside the existing
/// "Indicadores comerciais sensíveis" card (`report.viewSensitive`,
/// `CustomerDetailPage`). A caller who additionally holds `finance.view`
/// (OWNER/ADMIN/FINANCE) sees the full raw `CustomerCreditProfile` plus
/// "Editar" and "Exceção" actions (gated a second time by `finance.manage`,
/// same roles today but kept independent for when that ever diverges);
/// everyone else (e.g. `SALES_MANAGER`, who only holds `report.viewSensitive`)
/// sees a masked status badge only — the exact "vendedor entende o motivo
/// operacional sem acessar dado financeiro além do permitido" split
/// `tasks.md` requires.
class CustomerCreditPanel extends StatelessWidget {
  const CustomerCreditPanel({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final String userId;
  final PermissionService permissionService;
  final CustomerCreditCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.financeView,
      placeholderBuilder: (_) => const _CreditLoadingRow(),
      builder: (context, hasFinanceView) {
        return BlocProvider<CustomerCreditCubit>(
          create: (_) {
            final cubit = createCubit();
            if (hasFinanceView) {
              cubit.watchFullProfile(
                organizationId: organizationId,
                customerId: customerId,
              );
            } else {
              unawaited(
                cubit.loadMaskedStatus(
                  organizationId: organizationId,
                  companyId: companyId,
                  customerId: customerId,
                ),
              );
            }
            return cubit;
          },
          child: hasFinanceView
              ? _CreditDetailView(
                  organizationId: organizationId,
                  companyId: companyId,
                  customerId: customerId,
                  userId: userId,
                  permissionService: permissionService,
                )
              : const _CreditMaskedView(),
        );
      },
    );
  }
}

class _CreditLoadingRow extends StatelessWidget {
  const _CreditLoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

/// Masked (status-only) view — no `finance.view`.
class _CreditMaskedView extends StatelessWidget {
  const _CreditMaskedView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCreditCubit, CustomerCreditState>(
      builder: (context, state) {
        if (state.isLoading) return const _CreditLoadingRow();
        final check = state.maskedCheck;
        if (check == null) {
          return const _InlineEmpty(
            text: 'Não foi possível verificar a situação de crédito.',
          );
        }
        return _CreditStatusBadge(status: check.status, message: check.message);
      },
    );
  }
}

/// Full-detail view — `finance.view` granted.
class _CreditDetailView extends StatelessWidget {
  const _CreditDetailView({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.userId,
    required this.permissionService,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final String userId;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerCreditCubit, CustomerCreditState>(
      builder: (context, state) {
        if (state.isLoading) return const _CreditLoadingRow();
        final profile = state.profile;
        if (profile == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _InlineEmpty(
                text: 'Este cliente ainda não possui um perfil de crédito.',
              ),
              const SizedBox(height: AppSpacing.spacing8),
              PermissionBuilder(
                permissionService: permissionService,
                organizationId: organizationId,
                userId: userId,
                capability: Capability.financeManage,
                builder: (context, canManage) {
                  if (!canManage) return const SizedBox.shrink();
                  return AppButton(
                    label: 'Configurar crédito',
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _openEditSheet(context, profile: null),
                  );
                },
              ),
            ],
          );
        }

        final now = DateTime.now();
        final overrideActive = profile.creditOverride.isValidAt(now);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _CreditFigureRow(
              label: 'Limite de crédito',
              value: CurrencyFormatter.format(
                profile.creditLimit,
                CurrencyFormatter.legacyDefaultCurrency,
              ),
            ),
            _CreditFigureRow(
              label: 'Saldo em aberto',
              value: CurrencyFormatter.format(
                profile.openBalance,
                CurrencyFormatter.legacyDefaultCurrency,
              ),
            ),
            _CreditFigureRow(
              label: 'Saldo vencido',
              value: CurrencyFormatter.format(
                profile.overdueBalance,
                CurrencyFormatter.legacyDefaultCurrency,
              ),
              emphasize: profile.overdueBalance > 0,
            ),
            if (profile.financialScore != null)
              _CreditFigureRow(
                label: 'Score financeiro',
                value: profile.financialScore!.toStringAsFixed(0),
              ),
            _CreditFigureRow(
              label: 'Política de bloqueio',
              value: profile.blockPolicy.label,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            if (profile.manualBlock.active)
              _InlineEmpty(
                text:
                    'Bloqueado manualmente: ${profile.manualBlock.reason ?? 'sem motivo registrado'}.',
                isWarning: true,
              ),
            if (overrideActive)
              _InlineEmpty(
                text:
                    'Exceção vigente até ${_dateLabel(profile.creditOverride.expiresAt!)} '
                    '(${profile.creditOverride.reason ?? 'sem motivo registrado'}).',
              ),
            if (profile.isDataStaleAt(now))
              _InlineEmpty(
                text:
                    'Dado financeiro desatualizado desde ${_dateLabel(profile.dataUpdatedAt)}.',
                isWarning: true,
              ),
            const SizedBox(height: AppSpacing.spacing12),
            PermissionBuilder(
              permissionService: permissionService,
              organizationId: organizationId,
              userId: userId,
              capability: Capability.financeManage,
              builder: (context, canManage) {
                if (!canManage) return const SizedBox.shrink();
                return Wrap(
                  spacing: AppSpacing.spacing8,
                  runSpacing: AppSpacing.spacing8,
                  children: <Widget>[
                    AppButton(
                      label: 'Editar',
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          _openEditSheet(context, profile: profile),
                    ),
                    AppButton(
                      label: overrideActive
                          ? 'Revogar exceção'
                          : 'Conceder exceção',
                      variant: AppButtonVariant.text,
                      onPressed: () => overrideActive
                          ? context.read<CustomerCreditCubit>().revokeOverride(
                              organizationId: organizationId,
                              companyId: companyId,
                              customerId: customerId,
                            )
                          : _openOverrideSheet(context),
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditSheet(
    BuildContext context, {
    required CustomerCreditProfile? profile,
  }) {
    final cubit = context.read<CustomerCreditCubit>();
    return AppBottomSheet.show<void>(
      context: context,
      title: 'Crédito do cliente',
      contentKey: const Key('credit-profile-edit-sheet'),
      builder: (sheetContext) => BlocProvider<CustomerCreditCubit>.value(
        value: cubit,
        child: _CreditProfileEditForm(
          organizationId: organizationId,
          companyId: companyId,
          customerId: customerId,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _openOverrideSheet(BuildContext context) {
    final cubit = context.read<CustomerCreditCubit>();
    return AppBottomSheet.show<void>(
      context: context,
      title: 'Conceder exceção de crédito',
      contentKey: const Key('credit-override-sheet'),
      builder: (sheetContext) => BlocProvider<CustomerCreditCubit>.value(
        value: cubit,
        child: _CreditOverrideForm(
          organizationId: organizationId,
          companyId: companyId,
          customerId: customerId,
        ),
      ),
    );
  }
}

class _CreditFigureRow extends StatelessWidget {
  const _CreditFigureRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: colors.outline),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: emphasize ? colors.error : colors.onSurface,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditStatusBadge extends StatelessWidget {
  const _CreditStatusBadge({required this.status, required this.message});

  final CreditStatus status;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (icon, color) = switch (status) {
      CreditStatus.released => (Icons.check_circle_outline, colors.success),
      CreditStatus.nearLimit => (Icons.warning_amber_outlined, colors.warning),
      CreditStatus.approvalRequired => (
        Icons.hourglass_top_outlined,
        colors.warning,
      ),
      CreditStatus.blocked => (Icons.block_outlined, colors.error),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.spacing8),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text, this.isWarning = false});

  final String text;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.spacing4),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: isWarning ? colors.warning : colors.outline,
        ),
      ),
    );
  }
}

class _CreditProfileEditForm extends StatefulWidget {
  const _CreditProfileEditForm({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.profile,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final CustomerCreditProfile? profile;

  @override
  State<_CreditProfileEditForm> createState() => _CreditProfileEditFormState();
}

class _CreditProfileEditFormState extends State<_CreditProfileEditForm> {
  late final TextEditingController _limitController;
  late final TextEditingController _openBalanceController;
  late final TextEditingController _overdueBalanceController;
  late final TextEditingController _scoreController;
  late final TextEditingController _manualBlockReasonController;
  late CreditBlockPolicy _blockPolicy;
  late bool _manualBlockActive;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _limitController = TextEditingController(
      text: profile?.creditLimit.toStringAsFixed(2) ?? '',
    );
    _openBalanceController = TextEditingController(
      text: profile?.openBalance.toStringAsFixed(2) ?? '0',
    );
    _overdueBalanceController = TextEditingController(
      text: profile?.overdueBalance.toStringAsFixed(2) ?? '0',
    );
    _scoreController = TextEditingController(
      text: profile?.financialScore?.toStringAsFixed(0) ?? '',
    );
    _manualBlockReasonController = TextEditingController(
      text: profile?.manualBlock.reason ?? '',
    );
    _blockPolicy = profile?.blockPolicy ?? CreditBlockPolicy.alert;
    _manualBlockActive = profile?.manualBlock.active ?? false;
  }

  @override
  void dispose() {
    _limitController.dispose();
    _openBalanceController.dispose();
    _overdueBalanceController.dispose();
    _scoreController.dispose();
    _manualBlockReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerCreditCubit, CustomerCreditState>(
      listener: (context, state) {
        if (state.actionStatus == CustomerCreditActionStatus.success) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _limitController,
              label: 'Limite de crédito',
              isRequired: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _openBalanceController,
              label: 'Saldo em aberto',
              isRequired: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _overdueBalanceController,
              label: 'Saldo vencido',
              isRequired: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _scoreController,
              label: 'Score financeiro (opcional)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppDropdown<CreditBlockPolicy>(
              label: 'Política ao violar limite/inadimplência',
              closeSemanticLabel: 'Fechar',
              options: CreditBlockPolicy.values
                  .map(
                    (policy) => AppDropdownOption<CreditBlockPolicy>(
                      value: policy,
                      label: policy.label,
                    ),
                  )
                  .toList(growable: false),
              selectedValues: <CreditBlockPolicy>{_blockPolicy},
              onChanged: (selected) {
                if (selected.isNotEmpty) {
                  setState(() => _blockPolicy = selected.first);
                }
              },
            ),
            const SizedBox(height: AppSpacing.spacing12),
            SwitchListTile.adaptive(
              value: _manualBlockActive,
              contentPadding: EdgeInsets.zero,
              title: const Text('Bloqueio manual ativo'),
              onChanged: (value) => setState(() => _manualBlockActive = value),
            ),
            if (_manualBlockActive) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing4),
              AppTextField(
                controller: _manualBlockReasonController,
                label: 'Motivo do bloqueio manual',
                isRequired: true,
              ),
            ],
            const SizedBox(height: AppSpacing.spacing16),
            AppButton(
              label: 'Salvar',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : () => _submit(context),
            ),
          ],
        );
      },
    );
  }

  void _submit(BuildContext context) {
    final limit = double.tryParse(_limitController.text.replaceAll(',', '.'));
    final openBalance = double.tryParse(
      _openBalanceController.text.replaceAll(',', '.'),
    );
    final overdueBalance = double.tryParse(
      _overdueBalanceController.text.replaceAll(',', '.'),
    );
    if (limit == null || openBalance == null || overdueBalance == null) {
      return;
    }
    if (_manualBlockActive &&
        _manualBlockReasonController.text.trim().isEmpty) {
      return;
    }

    unawaited(
      context.read<CustomerCreditCubit>().updateProfile(
        organizationId: widget.organizationId,
        companyId: widget.companyId,
        customerId: widget.customerId,
        creditLimit: limit,
        openBalance: openBalance,
        overdueBalance: overdueBalance,
        blockPolicy: _blockPolicy,
        financialScore: double.tryParse(_scoreController.text),
        manualBlockActive: _manualBlockActive,
        manualBlockReason: _manualBlockActive
            ? _manualBlockReasonController.text.trim()
            : null,
      ),
    );
  }
}

class _CreditOverrideForm extends StatefulWidget {
  const _CreditOverrideForm({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
  });

  final String organizationId;
  final String companyId;
  final String customerId;

  @override
  State<_CreditOverrideForm> createState() => _CreditOverrideFormState();
}

class _CreditOverrideFormState extends State<_CreditOverrideForm> {
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _expiresAt;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerCreditCubit, CustomerCreditState>(
      listener: (context, state) {
        if (state.actionStatus == CustomerCreditActionStatus.success) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _reasonController,
              label: 'Motivo da exceção',
              isRequired: true,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppButton(
              label: _expiresAt == null
                  ? 'Selecionar validade'
                  : 'Válida até ${_dateLabel(_expiresAt!)}',
              variant: AppButtonVariant.secondary,
              onPressed: () => _pickExpiry(context),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppButton(
              label: 'Conceder exceção',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : () => _submit(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickExpiry(BuildContext context) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _expiresAt = selected);
    }
  }

  void _submit(BuildContext context) {
    final reason = _reasonController.text.trim();
    final expiresAt = _expiresAt;
    if (reason.isEmpty || expiresAt == null) return;

    unawaited(
      context.read<CustomerCreditCubit>().grantOverride(
        organizationId: widget.organizationId,
        companyId: widget.companyId,
        customerId: widget.customerId,
        reason: reason,
        expiresAt: expiresAt,
      ),
    );
  }
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
