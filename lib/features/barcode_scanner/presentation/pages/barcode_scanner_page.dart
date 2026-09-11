import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/product_code_resolution.dart';
import '../cubit/barcode_scan_cubit.dart';
import '../cubit/barcode_scan_state.dart';
import '../widgets/barcode_scanner_camera_surface.dart';
import '../widgets/manual_code_entry_field.dart';

/// Builds the live camera preview area — a seam so widget tests can swap in
/// a stub instead of the real `BarcodeScannerCameraSurface` (which needs a
/// real camera/platform channel `flutter test` does not have) while still
/// exercising every other TASK-216 requirement (permission denied, valid/
/// invalid reading, manual fallback) through the exact same
/// `BarcodeScanCubit.onCodeDetected` a real detection would call.
typedef BarcodeScannerCameraSurfaceBuilder =
    Widget Function(
      BuildContext context,
      ValueChanged<String> onDetect,
      VoidCallback onPermissionDenied,
      VoidCallback onUnsupported,
    );

Widget _defaultCameraSurfaceBuilder(
  BuildContext context,
  ValueChanged<String> onDetect,
  VoidCallback onPermissionDenied,
  VoidCallback onUnsupported,
) {
  return BarcodeScannerCameraSurface(
    onDetect: onDetect,
    onPermissionDenied: onPermissionDenied,
    onUnsupported: onUnsupported,
  );
}

/// Full scanning flow (TASK-216): camera preview with a manual fallback,
/// composed around [BarcodeScanCubit]. Pops with the resolved
/// [ProductCodeResolution] once the seller confirms "Usar este produto", or
/// with `null` if the sheet is dismissed without a confirmed match — the
/// caller (e.g. `OrderProductCatalogPage`) decides what to do with it
/// (typically: open the matched product exactly like a tapped catalog
/// card would, so price/stock/RBAC are always re-validated by that same,
/// unchanged flow).
class BarcodeScannerPage extends StatelessWidget {
  const BarcodeScannerPage({
    required this.organizationId,
    required this.createCubit,
    this.title = 'Escanear código',
    this.cameraSurfaceBuilder = _defaultCameraSurfaceBuilder,
    super.key,
  });

  final String organizationId;
  final BarcodeScanCubit Function() createCubit;
  final String title;
  final BarcodeScannerCameraSurfaceBuilder cameraSurfaceBuilder;

  static Future<ProductCodeResolution?> open(
    BuildContext context, {
    required String organizationId,
    required BarcodeScanCubit Function() createCubit,
    String title = 'Escanear código',
    BarcodeScannerCameraSurfaceBuilder cameraSurfaceBuilder =
        _defaultCameraSurfaceBuilder,
  }) {
    return Navigator.of(context).push<ProductCodeResolution>(
      MaterialPageRoute<ProductCodeResolution>(
        builder: (_) => BarcodeScannerPage(
          organizationId: organizationId,
          createCubit: createCubit,
          title: title,
          cameraSurfaceBuilder: cameraSurfaceBuilder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BarcodeScanCubit>(
      create: (_) => createCubit(),
      child: _BarcodeScannerView(
        organizationId: organizationId,
        title: title,
        cameraSurfaceBuilder: cameraSurfaceBuilder,
      ),
    );
  }
}

class _BarcodeScannerView extends StatefulWidget {
  const _BarcodeScannerView({
    required this.organizationId,
    required this.title,
    required this.cameraSurfaceBuilder,
  });

  final String organizationId;
  final String title;
  final BarcodeScannerCameraSurfaceBuilder cameraSurfaceBuilder;

  @override
  State<_BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<_BarcodeScannerView> {
  bool _manualEntryForced = false;

  void _onCodeDetected(String rawCode) {
    unawaited(
      context.read<BarcodeScanCubit>().onCodeDetected(
        organizationId: widget.organizationId,
        rawCode: rawCode,
      ),
    );
  }

  void _onManualSubmitted(String rawCode) {
    context.read<BarcodeScanCubit>().reportManualFallbackUsed();
    _onCodeDetected(rawCode);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: BlocBuilder<BarcodeScanCubit, BarcodeScanState>(
          builder: (context, state) {
            final showManualEntry =
                _manualEntryForced ||
                state.status == BarcodeScanStatus.permissionDenied;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (state.resolution != null && state.resolution!.isResolved)
                    _ResolutionResultCard(state: state)
                  else ...<Widget>[
                    if (!showManualEntry)
                      widget.cameraSurfaceBuilder(
                        context,
                        _onCodeDetected,
                        () => context
                            .read<BarcodeScanCubit>()
                            .reportPermissionDenied(),
                        () => setState(() => _manualEntryForced = true),
                      ),
                    const SizedBox(height: AppSpacing.spacing12),
                    TextButton(
                      onPressed: () =>
                          setState(() => _manualEntryForced = !showManualEntry),
                      child: Text(
                        showManualEntry
                            ? 'Usar a câmera'
                            : 'Digitar código manualmente',
                      ),
                    ),
                    if (showManualEntry) ...<Widget>[
                      const SizedBox(height: AppSpacing.spacing8),
                      ManualCodeEntryField(
                        onSubmitted: _onManualSubmitted,
                        isBusy: state.isBusy,
                        helperText:
                            state.status == BarcodeScanStatus.permissionDenied
                            ? 'Sem acesso à câmera: digite o código do produto.'
                            : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.spacing16),
                    _FeedbackMessage(state: state, colors: colors),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResolutionResultCard extends StatelessWidget {
  const _ResolutionResultCard({required this.state});

  final BarcodeScanState state;

  @override
  Widget build(BuildContext context) {
    final resolution = state.resolution!;
    final match = resolution.matches.first;
    final colors = context.colors;
    final variant = match.variant;
    final subtitle =
        resolution.status == ProductCodeResolutionStatus.multipleMatches
        ? '${resolution.matches.length} variações disponíveis — escolha cor/tamanho'
        : (variant == null
              ? 'Produto sem variante ativa no momento'
              : 'SKU ${variant.sku.value}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppRadius.radius12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(match.product.name, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  subtitle,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (state.occurrenceCount > 1) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing8),
                  Text(
                    'Lido ${state.occurrenceCount}x nesta sessão',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        AppButton(
          label: 'Usar este produto',
          expand: true,
          onPressed: () => Navigator.of(context).pop(resolution),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        AppButton(
          label: 'Escanear outro código',
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: () => context.read<BarcodeScanCubit>().resetForNextScan(),
        ),
      ],
    );
  }
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({required this.state, required this.colors});

  final BarcodeScanState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final message = switch (state.status) {
      BarcodeScanStatus.notFound =>
        'Código não encontrado. Confira o produto ou tente novamente.',
      BarcodeScanStatus.invalid => 'Digite ou escaneie um código válido.',
      BarcodeScanStatus.failure =>
        state.failure?.message ?? 'Não foi possível buscar este código.',
      BarcodeScanStatus.resolving => 'Buscando produto...',
      _ => null,
    };
    if (message == null) return const SizedBox.shrink();
    return Text(
      message,
      style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
    );
  }
}
