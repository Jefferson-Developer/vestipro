import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/post_sale_event_type.dart';
import '../cubit/register_post_sale_event_cubit.dart';
import '../cubit/register_post_sale_event_state.dart';

/// "Registrar evento de pós-venda" form (TASK-201, EPIC-30) — opened from the
/// order detail screen (TASK-104) for a pedido already em um status elegível
/// (em processamento/faturado/expedido/entregue). Tipo restrito aos marcos
/// manuais; descrição é sempre obrigatória para "problema reportado"
/// (revalidado, com autoridade final, por `registerPostSaleEvent`).
class RegisterPostSaleEventPage extends StatelessWidget {
  const RegisterPostSaleEventPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.orderId,
    required this.orderLabel,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String orderId;
  final String orderLabel;
  final RegisterPostSaleEventCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RegisterPostSaleEventCubit>(
      create: (_) => createCubit(),
      child: _RegisterPostSaleEventView(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        orderId: orderId,
        orderLabel: orderLabel,
      ),
    );
  }
}

class _RegisterPostSaleEventView extends StatelessWidget {
  const _RegisterPostSaleEventView({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.orderId,
    required this.orderLabel,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String orderId;
  final String orderLabel;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterPostSaleEventCubit, RegisterPostSaleEventState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failureMessage != current.failureMessage,
      listener: (context, state) {
        if (state.status == RegisterPostSaleEventStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Evento de pós-venda registrado.',
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
        final cubit = context.read<RegisterPostSaleEventCubit>();
        final isSubmitting =
            state.status == RegisterPostSaleEventStatus.submitting;

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Registrar evento de pós-venda — Pedido $orderLabel',
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppDropdown<PostSaleEventType>(
                    label: 'Marco de pós-venda',
                    isRequired: true,
                    closeSemanticLabel: 'Fechar seleção de marco',
                    isDisabled: isSubmitting,
                    errorText: state.fieldErrors['type'],
                    options: PostSaleEventType.manualValues
                        .map(
                          (type) => AppDropdownOption<PostSaleEventType>(
                            value: type,
                            label: type.label,
                          ),
                        )
                        .toList(growable: false),
                    selectedValues: <PostSaleEventType>{state.type},
                    onChanged: (selected) {
                      if (selected.isNotEmpty) {
                        cubit.setType(selected.first);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppTextField(
                    label: state.type.requiresDescription
                        ? 'Descrição do problema'
                        : 'Descrição (opcional)',
                    maxLines: 3,
                    isDisabled: isSubmitting,
                    errorText: state.fieldErrors['description'],
                    onChanged: cubit.setDescription,
                  ),
                  const SizedBox(height: AppSpacing.spacing24),
                  AppButton(
                    label: 'Registrar evento',
                    isLoading: isSubmitting,
                    isDisabled: isSubmitting,
                    onPressed: () => cubit.submit(
                      organizationId: organizationId,
                      companyId: companyId,
                      userId: userId,
                      orderId: orderId,
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
