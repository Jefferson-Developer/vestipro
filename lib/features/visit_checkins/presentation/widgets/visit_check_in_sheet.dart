import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// Bottom sheet collecting the two inputs a seller may customize per check-in
/// (TASK-178): an optional quick note and whether to share their current
/// location for *this* check-in specifically — never a persisted
/// preference, always asked again on the next check-in, so consent stays
/// explicit and per-action (see `CheckInVisitUseCase`).
class VisitCheckInSheet extends StatefulWidget {
  const VisitCheckInSheet({required this.customerName, super.key});

  final String customerName;

  /// Opens the sheet and resolves with the seller's chosen inputs, or
  /// `null` if they dismissed it without confirming — the caller must not
  /// start a check-in in that case.
  static Future<({String? note, bool shareLocation})?> show({
    required BuildContext context,
    required String customerName,
  }) {
    return AppBottomSheet.show<({String? note, bool shareLocation})>(
      context: context,
      title: 'Check-in em $customerName',
      builder: (_) => VisitCheckInSheet(customerName: customerName),
    );
  }

  @override
  State<VisitCheckInSheet> createState() => _VisitCheckInSheetState();
}

class _VisitCheckInSheetState extends State<VisitCheckInSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _shareLocation = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: _noteController,
          label: 'Observação (opcional)',
          hintText: 'Ex.: cliente confirmou pedido, sem estoque de X...',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        AppCheckbox(
          value: _shareLocation,
          label: 'Compartilhar minha localização neste check-in',
          semanticLabel: 'Compartilhar minha localização atual neste check-in',
          onChanged: (value) => setState(() => _shareLocation = value),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Sua localização só é usada para este check-in, mediante '
          'permissão do dispositivo — nunca em segundo plano. O check-in é '
          'registrado mesmo se você não compartilhar ou negar a permissão.',
          style: AppTypography.bodySmall.copyWith(color: colors.outline),
        ),
        const SizedBox(height: AppSpacing.spacing24),
        AppButton(
          label: 'Confirmar check-in',
          leadingIcon: Icons.check_circle_outline,
          onPressed: () => Navigator.of(
            context,
          ).pop((note: _noteController.text, shareLocation: _shareLocation)),
        ),
      ],
    );
  }
}
