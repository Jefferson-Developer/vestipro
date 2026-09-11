import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/design_system/design_system.dart';

/// Thin adapter around `package:mobile_scanner`'s live camera preview
/// (TASK-216) — the only widget in this feature that touches the plugin
/// directly, so `BarcodeScannerPage` (and its widget tests) only ever deal
/// with [onDetect]/[onPermissionDenied]/[onUnsupported] callbacks.
///
/// Not exercised by `flutter test` (no camera/platform channel in that
/// environment) — see this task's "Pendências" for the documented,
/// non-blocking limitation this implies (`AGENTS.md`: absence of a physical
/// device to test the camera is not, by itself, a real blocker).
class BarcodeScannerCameraSurface extends StatefulWidget {
  const BarcodeScannerCameraSurface({
    required this.onDetect,
    required this.onPermissionDenied,
    required this.onUnsupported,
    super.key,
  });

  final ValueChanged<String> onDetect;
  final VoidCallback onPermissionDenied;
  final VoidCallback onUnsupported;

  @override
  State<BarcodeScannerCameraSurface> createState() =>
      _BarcodeScannerCameraSurfaceState();
}

class _BarcodeScannerCameraSurfaceState
    extends State<BarcodeScannerCameraSurface> {
  late final MobileScannerController _controller;

  // `errorBuilder` runs synchronously as part of `MobileScanner`'s own
  // `build()`, itself nested inside this widget's ancestor's `build()` — so
  // notifying the caller here directly would call its `setState`/`Cubit.emit`
  // *during* a build, which Flutter forbids. Scheduling it for right after
  // the current frame (and only once, `errorBuilder` may be invoked again on
  // every rebuild while the error persists) avoids that.
  bool _hasReportedError = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  void _reportErrorAfterBuild(VoidCallback callback) {
    if (_hasReportedError) return;
    _hasReportedError = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.trim().isNotEmpty, orElse: () => '');
    if (rawValue.isEmpty) return;
    widget.onDetect(rawValue);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.radius12),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: MobileScanner(
          controller: _controller,
          onDetect: _handleDetect,
          errorBuilder: (context, error) {
            switch (error.errorCode) {
              case MobileScannerErrorCode.permissionDenied:
                _reportErrorAfterBuild(widget.onPermissionDenied);
              case MobileScannerErrorCode.unsupported:
                _reportErrorAfterBuild(widget.onUnsupported);
              default:
                break;
            }
            return _CameraUnavailableView(message: error.errorCode.message);
          },
        ),
      ),
    );
  }
}

class _CameraUnavailableView extends StatelessWidget {
  const _CameraUnavailableView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ColoredBox(
      color: colors.surfaceContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.camera_alt_outlined, color: colors.onSurface),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
