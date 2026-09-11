import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

/// The camera-unavailable fallback required by TASK-216 ("fallback manual
/// para plataformas/dispositivos sem câmera ou permissão") — also the entry
/// point every widget test uses to exercise a "leitura válida"/"leitura
/// inválida" without a real camera, since [onSubmitted] funnels into the
/// exact same `BarcodeScanCubit.onCodeDetected` a camera detection would.
class ManualCodeEntryField extends StatefulWidget {
  const ManualCodeEntryField({
    required this.onSubmitted,
    this.isBusy = false,
    this.helperText,
    super.key,
  });

  final ValueChanged<String> onSubmitted;
  final bool isBusy;
  final String? helperText;

  @override
  State<ManualCodeEntryField> createState() => _ManualCodeEntryFieldState();
}

class _ManualCodeEntryFieldState extends State<ManualCodeEntryField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text;
    widget.onSubmitted(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppTextField(
          controller: _controller,
          label: 'Código do produto',
          hintText: 'Digite o SKU, EAN ou referência',
          helperText: widget.helperText,
          isDisabled: widget.isBusy,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _submit(),
          semanticLabel: 'Digitar código do produto manualmente',
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppButton(
          label: 'Buscar código',
          leadingIcon: Icons.search,
          isLoading: widget.isBusy,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}
