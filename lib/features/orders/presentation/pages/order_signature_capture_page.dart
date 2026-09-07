import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/order.dart';
import '../../domain/value_objects/order_signer_role.dart';
import '../bloc/order_signature_cubit.dart';
import '../bloc/order_signature_state.dart';
import '../widgets/order_signature_pad.dart';

/// "Assinar pedido" screen (EPIC-13, TASK-180) — captures the electronic
/// signature closing [order] via [OrderSignaturePad] and, through
/// [OrderSignatureCubit], persists it offline-first and syncs it to
/// `signOrder` right away when connectivity allows.
///
/// Pushed directly by `OrderHistoryPage` (`Navigator.push`, never a typed
/// `AppRoute` of its own — same "simple, contextual page pushed straight
/// from the screen that owns the flow" precedent `ReportPdfPreviewPage`
/// already sets), sharing the very same [OrderSignatureCubit] instance the
/// history page already holds (`BlocProvider.value`) so the "Assinar
/// pedido"/"Ver comprovante" actions there immediately reflect the outcome
/// without an extra reload round-trip.
class OrderSignatureCapturePage extends StatefulWidget {
  const OrderSignatureCapturePage({
    required this.order,
    required this.signedByUserId,
    super.key,
  });

  final Order order;

  /// The authenticated seller operating this device — never the signer's
  /// own identity (see `OrderSignature.signedByUserId`'s own docs).
  final String signedByUserId;

  @override
  State<OrderSignatureCapturePage> createState() =>
      _OrderSignatureCapturePageState();
}

class _OrderSignatureCapturePageState extends State<OrderSignatureCapturePage> {
  final GlobalKey<OrderSignaturePadState> _padKey =
      GlobalKey<OrderSignaturePadState>();
  final TextEditingController _signerNameController = TextEditingController();
  OrderSignerRole _signerRole = OrderSignerRole.customer;

  @override
  void dispose() {
    _signerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderSignatureCubit, OrderSignatureState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == OrderSignatureFlowStatus.synced ||
            (state.status == OrderSignatureFlowStatus.captured &&
                state.failure == null)) {
          AppSnackbar.show(
            context,
            message: state.status == OrderSignatureFlowStatus.synced
                ? 'Pedido assinado e sincronizado com sucesso.'
                : 'Assinatura capturada. Será sincronizada assim que '
                      'houver conexão.',
            variant: AppSnackbarVariant.success,
          );
          Navigator.of(context).pop();
        } else if (state.status == OrderSignatureFlowStatus.failure) {
          AppSnackbar.show(
            context,
            message:
                state.failure?.message ??
                'Não foi possível capturar a assinatura.',
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        final isBusy =
            state.status == OrderSignatureFlowStatus.capturing ||
            state.status == OrderSignatureFlowStatus.syncing;
        return Scaffold(
          appBar: AppBar(title: const Text('Assinar pedido')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Quem está assinando?', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spacing8),
                AppDropdown<OrderSignerRole>(
                  options: const <AppDropdownOption<OrderSignerRole>>[
                    AppDropdownOption(
                      value: OrderSignerRole.customer,
                      label: 'Cliente',
                    ),
                    AppDropdownOption(
                      value: OrderSignerRole.seller,
                      label: 'Vendedor',
                    ),
                  ],
                  selectedValues: <OrderSignerRole>{_signerRole},
                  closeSemanticLabel: 'Confirmar seleção de quem assina',
                  onChanged: (values) => setState(() {
                    _signerRole = values.isEmpty
                        ? OrderSignerRole.customer
                        : values.first;
                  }),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                AppTextField(
                  controller: _signerNameController,
                  label: 'Nome de quem assina',
                  hintText: 'Nome completo',
                  semanticLabel: 'Nome de quem assina o pedido',
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Text('Assinatura', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spacing8),
                OrderSignaturePad(key: _padKey),
                const SizedBox(height: AppSpacing.spacing8),
                AppButton(
                  label: 'Limpar assinatura',
                  variant: AppButtonVariant.text,
                  onPressed: isBusy
                      ? null
                      : () => _padKey.currentState?.clear(),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  'A assinatura por desenho em tela é o modelo de assinatura '
                  'eletrônica desta versão do VestiPro. Ela fica anexada de '
                  'forma imutável a este pedido e não pode ser removida ou '
                  'substituída.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                AppButton(
                  label: 'Confirmar assinatura',
                  leadingIcon: Icons.draw_outlined,
                  isLoading: isBusy,
                  onPressed: isBusy ? null : () => _submit(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final pad = _padKey.currentState;
    if (pad == null || !pad.hasStrokes) {
      AppSnackbar.show(
        context,
        message: 'Desenhe a assinatura antes de confirmar.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }
    if (_signerNameController.text.trim().isEmpty) {
      AppSnackbar.show(
        context,
        message: 'Informe o nome de quem está assinando.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }

    final cubit = context.read<OrderSignatureCubit>();
    final imageBytes = await pad.exportPng();
    if (imageBytes == null) {
      if (!context.mounted) return;
      AppSnackbar.show(
        context,
        message: 'Desenhe a assinatura antes de confirmar.',
        variant: AppSnackbarVariant.warning,
      );
      return;
    }

    await cubit.captureAndSync(
      order: widget.order,
      signerRole: _signerRole,
      signedByUserId: widget.signedByUserId,
      signedByName: _signerNameController.text,
      imageBytes: imageBytes,
    );
  }
}
