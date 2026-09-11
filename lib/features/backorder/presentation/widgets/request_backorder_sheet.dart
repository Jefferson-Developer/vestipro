import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/backorder_origin.dart';
import '../../domain/value_objects/backorder_priority.dart';
import '../cubit/request_backorder_cubit.dart';
import '../cubit/request_backorder_state.dart';

/// Formulário de solicitação de backorder/estoque futuro (TASK-215,
/// EPIC-32) — aberto a partir do catálogo/grade comercial ou de um pedido em
/// andamento quando a variante não tem estoque pronta entrega suficiente
/// (`VariantAvailabilityStatus.futureStock`/`unavailable`). Nunca promete
/// disponibilidade: apenas registra a demanda (`tasks.md`: "Backorder não
/// reduz saldo de estoque atual nem garante entrega sem confirmação
/// posterior").
class RequestBackorderSheet extends StatefulWidget {
  const RequestBackorderSheet({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.productId,
    required this.variantId,
    required this.origin,
    this.sku,
    this.sellerId,
    this.relatedOrderId,
    this.relatedOrderItemId,
    this.estimatedUnitPrice,
    this.maxAvailableQuantity,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final String productId;
  final String variantId;
  final BackorderOrigin origin;
  final String? sku;
  final String? sellerId;
  final String? relatedOrderId;
  final String? relatedOrderItemId;
  final double? estimatedUnitPrice;

  /// Estoque pronta entrega já visível na tela de origem, se houver — apenas
  /// exibido como contexto (nunca reenviado como garantia de disponibilidade
  /// futura).
  final int? maxAvailableQuantity;

  /// Opens this form as a modal bottom sheet, resolving to the created
  /// `backorderId` on success, or `null` if dismissed without submitting.
  static Future<String?> show({
    required BuildContext context,
    required RequestBackorderCubit Function() createCubit,
    required String organizationId,
    required String companyId,
    required String customerId,
    required String productId,
    required String variantId,
    required BackorderOrigin origin,
    String? sku,
    String? sellerId,
    String? relatedOrderId,
    String? relatedOrderItemId,
    double? estimatedUnitPrice,
    int? maxAvailableQuantity,
  }) {
    return AppBottomSheet.show<String>(
      context: context,
      title: 'Solicitar estoque futuro',
      contentKey: const Key('request-backorder-sheet'),
      builder: (sheetContext) => BlocProvider<RequestBackorderCubit>(
        create: (_) => createCubit(),
        child: RequestBackorderSheet(
          organizationId: organizationId,
          companyId: companyId,
          customerId: customerId,
          productId: productId,
          variantId: variantId,
          origin: origin,
          sku: sku,
          sellerId: sellerId,
          relatedOrderId: relatedOrderId,
          relatedOrderItemId: relatedOrderItemId,
          estimatedUnitPrice: estimatedUnitPrice,
          maxAvailableQuantity: maxAvailableQuantity,
        ),
      ),
    );
  }

  @override
  State<RequestBackorderSheet> createState() => _RequestBackorderSheetState();
}

class _RequestBackorderSheetState extends State<RequestBackorderSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _notesController;
  BackorderPriority _priority = BackorderPriority.normal;
  DateTime? _requestedDeliveryDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestBackorderCubit, RequestBackorderState>(
      listener: (context, state) {
        if (state.status == RequestBackorderStatus.success) {
          Navigator.of(context).pop(state.lastBackorderId);
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.maxAvailableQuantity != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                child: Text(
                  'Estoque pronta entrega atual: ${widget.maxAvailableQuantity}'
                  ' unidade(s). Esta solicitação não reserva nem garante '
                  'estoque — apenas registra a demanda.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.outline,
                  ),
                ),
              ),
            AppTextField(
              controller: _quantityController,
              label: 'Quantidade desejada',
              isRequired: true,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            DropdownButtonFormField<BackorderPriority>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Prioridade'),
              items: BackorderPriority.values
                  .map(
                    (priority) => DropdownMenuItem<BackorderPriority>(
                      value: priority,
                      child: Text(priority.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _priority = value);
              },
            ),
            const SizedBox(height: AppSpacing.spacing12),
            InkWell(
              onTap: () => _pickDate(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data desejada para entrega (opcional)',
                ),
                child: Text(
                  _requestedDeliveryDate == null
                      ? 'Sem data definida'
                      : _dateLabel(_requestedDeliveryDate!),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _notesController,
              label: 'Observações (opcional)',
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            if (state.status == RequestBackorderStatus.failure)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
                child: Text(
                  state.failureMessage ??
                      'Não foi possível registrar o backorder.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            AppButton(
              label: 'Solicitar estoque futuro',
              isLoading: state.isSubmitting,
              onPressed: state.isSubmitting ? null : () => _submit(context),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requestedDeliveryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _requestedDeliveryDate = picked);
    }
  }

  void _submit(BuildContext context) {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) return;

    unawaited(
      context.read<RequestBackorderCubit>().submit(
        organizationId: widget.organizationId,
        companyId: widget.companyId,
        customerId: widget.customerId,
        productId: widget.productId,
        variantId: widget.variantId,
        sku: widget.sku,
        quantity: quantity,
        origin: widget.origin,
        priority: _priority,
        sellerId: widget.sellerId,
        relatedOrderId: widget.relatedOrderId,
        relatedOrderItemId: widget.relatedOrderItemId,
        requestedDeliveryDate: _requestedDeliveryDate,
        estimatedUnitPrice: widget.estimatedUnitPrice,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
