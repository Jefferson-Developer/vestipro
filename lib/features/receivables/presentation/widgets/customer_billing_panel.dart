import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/receivable.dart';
import '../../domain/value_objects/aging_bucket.dart';
import '../../domain/value_objects/billing_status.dart';
import '../../domain/value_objects/receivable_status.dart';
import '../bloc/customer_billing_cubit.dart';
import '../bloc/customer_billing_state.dart';

/// Situação financeira section (TASK-213, EPIC-32) — usado tanto no cliente
/// 360º (sem [orderId], cobre todos os títulos do cliente) quanto no detalhe
/// do pedido (com [orderId], escopado a esse pedido). Mesma divisão
/// "detalhe completo x status mascarado" de [CustomerCreditPanel] (TASK-212):
/// `finance.view` vê faturas/títulos e aging reais; qualquer outro papel
/// autorizado a ver esta tela só enxerga um status acionável, sem valores.
class CustomerBillingPanel extends StatelessWidget {
  const CustomerBillingPanel({
    required this.organizationId,
    required this.customerId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    this.orderId,
    super.key,
  });

  final String organizationId;
  final String customerId;
  final String? orderId;
  final String userId;
  final PermissionService permissionService;
  final CustomerBillingCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.financeView,
      placeholderBuilder: (_) => const _BillingLoadingRow(),
      builder: (context, hasFinanceView) {
        return BlocProvider<CustomerBillingCubit>(
          create: (_) {
            final cubit = createCubit();
            if (hasFinanceView) {
              cubit.watchFullDetail(
                organizationId: organizationId,
                customerId: customerId,
                orderId: orderId,
              );
            } else {
              unawaited(
                cubit.loadMaskedStatus(
                  organizationId: organizationId,
                  customerId: customerId,
                  orderId: orderId,
                ),
              );
            }
            return cubit;
          },
          child: hasFinanceView
              ? _BillingDetailView(
                  organizationId: organizationId,
                  userId: userId,
                  permissionService: permissionService,
                )
              : const _BillingMaskedView(),
        );
      },
    );
  }
}

class _BillingLoadingRow extends StatelessWidget {
  const _BillingLoadingRow();

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
class _BillingMaskedView extends StatelessWidget {
  const _BillingMaskedView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerBillingCubit, CustomerBillingState>(
      builder: (context, state) {
        if (state.isLoading) return const _BillingLoadingRow();
        final check = state.maskedCheck;
        if (check == null) {
          return const _InlineEmpty(
            text: 'Não foi possível verificar a situação financeira.',
          );
        }
        final colors = context.colors;
        final (icon, color) = switch (check.status) {
          BillingStatus.upToDate => (
            Icons.check_circle_outline,
            colors.success,
          ),
          BillingStatus.hasOpen => (Icons.schedule_outlined, colors.outline),
          BillingStatus.hasOverdue => (
            Icons.warning_amber_outlined,
            colors.error,
          ),
        };
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Text(
                check.message,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Full-detail view — `finance.view` granted.
class _BillingDetailView extends StatelessWidget {
  const _BillingDetailView({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBillingCubit, CustomerBillingState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus,
      listener: (context, state) {
        if (state.actionStatus == CustomerBillingActionStatus.success) {
          AppSnackbar.show(context, message: 'Pagamento registrado.');
        } else if (state.actionStatus == CustomerBillingActionStatus.failure) {
          AppSnackbar.show(
            context,
            message:
                state.actionFailure?.message ??
                'Não foi possível registrar o pagamento.',
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) return const _BillingLoadingRow();
        final receivables = state.receivables;
        if (receivables.isEmpty) {
          return const _InlineEmpty(
            text: 'Nenhuma fatura/título registrado para este cliente.',
          );
        }

        final now = DateTime.now();
        final open =
            receivables
                .where((receivable) => !receivable.status.isSettled)
                .toList(growable: false)
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
        final settled = receivables
            .where((receivable) => receivable.status.isSettled)
            .toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _AgingSummaryRow(receivables: open, now: now),
            const SizedBox(height: AppSpacing.spacing12),
            for (final receivable in open)
              _ReceivableRow(
                receivable: receivable,
                now: now,
                organizationId: organizationId,
                userId: userId,
                permissionService: permissionService,
              ),
            if (settled.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Quitadas/estornadas',
                style: AppTypography.labelMedium.copyWith(
                  color: context.colors.outline,
                ),
              ),
              for (final receivable in settled)
                _ReceivableRow(
                  receivable: receivable,
                  now: now,
                  organizationId: organizationId,
                  userId: userId,
                  permissionService: permissionService,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _AgingSummaryRow extends StatelessWidget {
  const _AgingSummaryRow({required this.receivables, required this.now});

  final List<Receivable> receivables;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final totals = <AgingBucket, double>{
      for (final bucket in AgingBucket.values) bucket: 0,
    };
    for (final receivable in receivables) {
      final bucket = receivable.agingBucketAt(now);
      totals[bucket] = (totals[bucket] ?? 0) + receivable.outstandingAmount;
    }
    final currency = receivables.isEmpty
        ? CurrencyFormatter.legacyDefaultCurrency
        : receivables.first.currency;

    return Wrap(
      spacing: AppSpacing.spacing12,
      runSpacing: AppSpacing.spacing8,
      children: AgingBucket.values
          .map(
            (bucket) => _AgingChip(
              label: bucket.label,
              value: CurrencyFormatter.format(totals[bucket] ?? 0, currency),
              emphasize:
                  bucket != AgingBucket.current && (totals[bucket] ?? 0) > 0,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AgingChip extends StatelessWidget {
  const _AgingChip({
    required this.label,
    required this.value,
    required this.emphasize,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: emphasize
            ? colors.error.withValues(alpha: 0.08)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: colors.outline),
          ),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: emphasize ? colors.error : colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivableRow extends StatelessWidget {
  const _ReceivableRow({
    required this.receivable,
    required this.now,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final Receivable receivable;
  final DateTime now;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emphasize = receivable.status == ReceivableStatus.overdue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Parcela ${receivable.installmentNumber} · vence ${_dateLabel(receivable.dueDate)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${receivable.status.label} · ${CurrencyFormatter.format(receivable.outstandingAmount, receivable.currency)} em aberto '
                  '(de ${CurrencyFormatter.format(receivable.amount, receivable.currency)})',
                  style: AppTypography.bodySmall.copyWith(
                    color: emphasize ? colors.error : colors.outline,
                  ),
                ),
              ],
            ),
          ),
          if (!receivable.status.isSettled)
            PermissionBuilder(
              permissionService: permissionService,
              organizationId: organizationId,
              userId: userId,
              capability: Capability.financeManage,
              builder: (context, canManage) {
                if (!canManage) return const SizedBox.shrink();
                return AppButton(
                  label: 'Registrar pagamento',
                  variant: AppButtonVariant.text,
                  onPressed: () => _openRegisterPaymentSheet(context),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openRegisterPaymentSheet(BuildContext context) {
    final cubit = context.read<CustomerBillingCubit>();
    return AppBottomSheet.show<void>(
      context: context,
      title: 'Registrar pagamento',
      contentKey: const Key('receivable-register-payment-sheet'),
      builder: (sheetContext) => BlocProvider<CustomerBillingCubit>.value(
        value: cubit,
        child: _RegisterPaymentForm(
          organizationId: organizationId,
          receivable: receivable,
        ),
      ),
    );
  }
}

class _RegisterPaymentForm extends StatefulWidget {
  const _RegisterPaymentForm({
    required this.organizationId,
    required this.receivable,
  });

  final String organizationId;
  final Receivable receivable;

  @override
  State<_RegisterPaymentForm> createState() => _RegisterPaymentFormState();
}

class _RegisterPaymentFormState extends State<_RegisterPaymentForm> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.receivable.outstandingAmount.toStringAsFixed(2),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBillingCubit, CustomerBillingState>(
      listener: (context, state) {
        if (state.actionStatus == CustomerBillingActionStatus.success) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Confirma o recebimento deste pagamento? Esta ação não pode ser '
              'desfeita pelo aplicativo.',
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _amountController,
              label: 'Valor recebido',
              isRequired: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _noteController,
              label: 'Observação (opcional)',
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppButton(
              label: 'Confirmar pagamento',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : () => _submit(context),
            ),
          ],
        );
      },
    );
  }

  void _submit(BuildContext context) {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;

    unawaited(
      context.read<CustomerBillingCubit>().registerPayment(
        organizationId: widget.organizationId,
        receivableId: widget.receivable.id,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: context.colors.outline),
    );
  }
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
