import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/value_objects/return_reason_category.dart';
import '../cubit/return_request_form_cubit.dart';
import '../cubit/return_request_form_state.dart';

/// "Solicitar devolução" form (TASK-199, EPIC-30) — opened from the order
/// detail screen (TASK-104) for a pedido already in an elegible
/// (invoiced/shipped/delivered) status. Motivo categorizado é sempre
/// obrigatório; a quantidade de cada item nunca pode exceder a do próprio
/// [order] (revalidado, com autoridade final, por `createReturnRequest`).
class ReturnRequestFormPage extends StatelessWidget {
  const ReturnRequestFormPage({
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
  final ReturnRequestFormCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReturnRequestFormCubit>(
      create: (_) => createCubit(),
      child: _ReturnRequestFormView(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        order: order,
      ),
    );
  }
}

class _ReturnRequestFormView extends StatelessWidget {
  const _ReturnRequestFormView({
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
    return BlocConsumer<ReturnRequestFormCubit, ReturnRequestFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failureMessage != current.failureMessage,
      listener: (context, state) {
        if (state.status == ReturnRequestFormStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Solicitação de devolução enviada.',
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
        final cubit = context.read<ReturnRequestFormCubit>();
        final isSubmitting = state.status == ReturnRequestFormStatus.submitting;

        return Scaffold(
          body: AppAdminPageLayout(
            title:
                'Solicitar devolução — Pedido ${order.orderNumber ?? order.id}',
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
                      child: _ReturnItemRow(
                        productId: item.productId,
                        maxQuantity: item.quantity,
                        quantity: state.selectedQuantities[item.id] ?? 0,
                        isDisabled: isSubmitting,
                        onChanged: (quantity) =>
                            cubit.setQuantity(item.id, quantity),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppDropdown<ReturnReasonCategory>(
                    label: 'Motivo da devolução',
                    isRequired: true,
                    closeSemanticLabel: 'Fechar seleção de motivo',
                    isDisabled: isSubmitting,
                    errorText: state.fieldErrors['reasonCategory'],
                    options: ReturnReasonCategory.values
                        .map(
                          (category) => AppDropdownOption<ReturnReasonCategory>(
                            value: category,
                            label: category.label,
                          ),
                        )
                        .toList(growable: false),
                    selectedValues: state.reasonCategory == null
                        ? const <ReturnReasonCategory>{}
                        : <ReturnReasonCategory>{state.reasonCategory!},
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
                  const SizedBox(height: AppSpacing.spacing16),
                  _EvidenceSection(
                    organizationId: organizationId,
                    state: state,
                    cubit: cubit,
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

class _ReturnItemRow extends StatelessWidget {
  const _ReturnItemRow({
    required this.productId,
    required this.maxQuantity,
    required this.quantity,
    required this.isDisabled,
    required this.onChanged,
  });

  final String productId;
  final int maxQuantity;
  final int quantity;
  final bool isDisabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'Produto $productId (máx. $maxQuantity un.)',
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
          AppQuantityStepper(
            quantity: quantity,
            maxQuantity: maxQuantity,
            isDisabled: isDisabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _EvidenceSection extends StatelessWidget {
  const _EvidenceSection({
    required this.organizationId,
    required this.state,
    required this.cubit,
  });

  final String organizationId;
  final ReturnRequestFormState state;
  final ReturnRequestFormCubit cubit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Evidência (opcional)',
          style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        for (final url in state.evidenceUrls)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ),
                AppIconButton(
                  icon: Icons.delete_outline,
                  semanticLabel: 'Remover evidência',
                  variant: AppButtonVariant.text,
                  onPressed: () => cubit.removeEvidenceUrl(url),
                ),
              ],
            ),
          ),
        if (state.isUploadingEvidence)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
            child: LinearProgressIndicator(),
          ),
        AppButton(
          label: 'Adicionar foto',
          leadingIcon: Icons.add_photo_alternate_outlined,
          variant: AppButtonVariant.secondary,
          isDisabled: state.isUploadingEvidence,
          onPressed: () async {
            final file = await ImagePicker().pickImage(
              source: ImageSource.gallery,
            );
            if (file == null) return;
            final bytes = await file.readAsBytes();
            await cubit.uploadEvidence(
              organizationId: organizationId,
              bytes: bytes,
              fileName: '${DateTime.now().microsecondsSinceEpoch}.jpg',
            );
          },
        ),
      ],
    );
  }
}
