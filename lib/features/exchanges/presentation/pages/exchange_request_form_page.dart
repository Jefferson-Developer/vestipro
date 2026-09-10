import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_item.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../domain/value_objects/exchange_reason_category.dart';
import '../cubit/exchange_request_form_cubit.dart';
import '../cubit/exchange_request_form_state.dart';

/// "Solicitar troca" form (TASK-200, EPIC-30) — opened from the order detail
/// screen (TASK-104) for a pedido already in an elegible (invoiced/shipped/
/// delivered) status, same eligibility window as devoluções (TASK-199).
/// Motivo categorizado é sempre obrigatório; a seleção da variante de
/// destino mostra a disponibilidade em tempo real (feedback de UI apenas —
/// a checagem que realmente autoriza a troca é sempre revalidada, com
/// autoridade final, por `createExchangeRequest`/`resolveExchangeRequest`).
class ExchangeRequestFormPage extends StatelessWidget {
  const ExchangeRequestFormPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.order,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final Order order;
  final ExchangeRequestFormCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExchangeRequestFormCubit>(
      create: (_) => createCubit(),
      child: _ExchangeRequestFormView(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        order: order,
      ),
    );
  }
}

class _ExchangeRequestFormView extends StatelessWidget {
  const _ExchangeRequestFormView({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.order,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final Order order;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExchangeRequestFormCubit, ExchangeRequestFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failureMessage != current.failureMessage,
      listener: (context, state) {
        if (state.status == ExchangeRequestFormStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Solicitação de troca enviada.',
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop(true);
        } else if (state.failureMessage != null) {
          AppSnackbar.show(
            context,
            message: state.failureMessage!,
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<ExchangeRequestFormCubit>();
        final isSubmitting =
            state.status == ExchangeRequestFormStatus.submitting;

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Solicitar troca — Pedido ${order.orderNumber ?? order.id}',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Itens do pedido',
                    style: AppTypography.titleMedium.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (state.fieldErrors['items'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                      child: Text(
                        state.fieldErrors['items']!,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.colors.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.spacing12),
                  for (final item in order.items)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.spacing12,
                      ),
                      child: _ExchangeItemRow(
                        organizationId: organizationId,
                        item: item,
                        quantity: state.selectedQuantities[item.id] ?? 0,
                        selectedDestinationVariantId:
                            state.selectedDestinationVariantId[item.id],
                        destinationVariants:
                            state.destinationVariantsByOrderItem[item.id] ??
                            const [],
                        isLoadingDestinationVariants:
                            state.loadingDestinationVariantsForOrderItem ==
                            item.id,
                        destinationAvailability: state.destinationAvailability,
                        isCheckingAvailability:
                            state.checkingAvailabilityForVariant != null,
                        isDisabled: isSubmitting,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppDropdown<ExchangeReasonCategory>(
                    label: 'Motivo da troca',
                    isRequired: true,
                    closeSemanticLabel: 'Fechar seleção de motivo',
                    isDisabled: isSubmitting,
                    errorText: state.fieldErrors['reasonCategory'],
                    options: ExchangeReasonCategory.values
                        .map(
                          (category) =>
                              AppDropdownOption<ExchangeReasonCategory>(
                                value: category,
                                label: category.label,
                              ),
                        )
                        .toList(growable: false),
                    selectedValues: state.reasonCategory == null
                        ? const <ExchangeReasonCategory>{}
                        : <ExchangeReasonCategory>{state.reasonCategory!},
                    onChanged: (selected) {
                      if (selected.isNotEmpty) {
                        cubit.setReasonCategory(selected.first);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppTextField(
                    label: 'Detalhes (opcional)',
                    maxLines: 3,
                    isDisabled: isSubmitting,
                    onChanged: cubit.setReasonDetails,
                  ),
                  const SizedBox(height: AppSpacing.spacing24),
                  AppButton(
                    label: 'Enviar solicitação',
                    isLoading: isSubmitting,
                    isDisabled: isSubmitting,
                    onPressed: () => cubit.submit(
                      organizationId: organizationId,
                      companyId: companyId,
                      userId: userId,
                      orderId: order.id,
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

class _ExchangeItemRow extends StatefulWidget {
  const _ExchangeItemRow({
    required this.organizationId,
    required this.item,
    required this.quantity,
    required this.selectedDestinationVariantId,
    required this.destinationVariants,
    required this.isLoadingDestinationVariants,
    required this.destinationAvailability,
    required this.isCheckingAvailability,
    required this.isDisabled,
  });

  final String organizationId;
  final OrderItem item;
  final int quantity;
  final String? selectedDestinationVariantId;
  final List<ProductVariant> destinationVariants;
  final bool isLoadingDestinationVariants;
  final Map<String, int> destinationAvailability;
  final bool isCheckingAvailability;
  final bool isDisabled;

  @override
  State<_ExchangeItemRow> createState() => _ExchangeItemRowState();
}

class _ExchangeItemRowState extends State<_ExchangeItemRow> {
  @override
  void initState() {
    super.initState();
    unawaited(
      context.read<ExchangeRequestFormCubit>().loadDestinationVariants(
        organizationId: widget.organizationId,
        orderItemId: widget.item.id,
        productId: widget.item.productId,
        originVariantId: widget.item.variantId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final cubit = context.read<ExchangeRequestFormCubit>();
    final availability = widget.selectedDestinationVariantId == null
        ? null
        : widget.destinationAvailability[widget.selectedDestinationVariantId];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Produto ${widget.item.productId} (máx. ${widget.item.quantity} un.)',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              AppQuantityStepper(
                quantity: widget.quantity,
                maxQuantity: widget.item.quantity,
                isDisabled: widget.isDisabled,
                onChanged: (quantity) =>
                    cubit.setQuantity(widget.item.id, quantity),
              ),
            ],
          ),
          if (widget.quantity > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            if (widget.isLoadingDestinationVariants)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
                child: LinearProgressIndicator(),
              )
            else
              AppDropdown<String>(
                label: 'Nova cor/tamanho (mesmo produto)',
                isRequired: true,
                closeSemanticLabel: 'Fechar seleção de variante',
                isDisabled: widget.isDisabled,
                options: widget.destinationVariants
                    .map<AppDropdownOption<String>>(
                      (variant) => AppDropdownOption<String>(
                        value: variant.id,
                        label: variant.sku.value,
                      ),
                    )
                    .toList(growable: false),
                selectedValues: widget.selectedDestinationVariantId == null
                    ? const <String>{}
                    : <String>{widget.selectedDestinationVariantId!},
                onChanged: (selected) {
                  if (selected.isNotEmpty) {
                    unawaited(
                      cubit.selectDestinationVariant(
                        organizationId: widget.organizationId,
                        orderItemId: widget.item.id,
                        destinationVariantId: selected.first,
                      ),
                    );
                  }
                },
              ),
            if (widget.selectedDestinationVariantId != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.spacing4),
                child: Text(
                  widget.isCheckingAvailability
                      ? 'Consultando estoque...'
                      : 'Estoque disponível: ${availability ?? 0} un.',
                  style: AppTypography.bodySmall.copyWith(
                    color: (availability ?? 0) >= widget.quantity
                        ? colors.outline
                        : colors.error,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
