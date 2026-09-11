import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_code_resolution.dart';
import '../../domain/usecases/resolve_product_code_use_case.dart';
import 'barcode_scan_state.dart';

/// Drives one scanning session (TASK-216): a code detected by the camera or
/// typed into the manual fallback field both funnel through
/// [onCodeDetected], so every widget test that exercises "leitura válida"/
/// "leitura inválida" can do so via the manual field alone, without a real
/// camera/platform channel.
@injectable
final class BarcodeScanCubit extends Cubit<BarcodeScanState> {
  BarcodeScanCubit(this._resolveProductCode, this._analyticsService)
    : super(const BarcodeScanState());

  final ResolveProductCodeUseCase _resolveProductCode;
  final AnalyticsService _analyticsService;
  final Map<String, int> _occurrencesByCode = <String, int>{};

  Future<void> onCodeDetected({
    required String organizationId,
    required String rawCode,
  }) async {
    if (state.status == BarcodeScanStatus.resolving) return;

    final trimmed = rawCode.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          status: BarcodeScanStatus.invalid,
          clearFailure: true,
          clearResolution: true,
        ),
      );
      return;
    }

    final occurrenceCount = (_occurrencesByCode[trimmed] ?? 0) + 1;
    _occurrencesByCode[trimmed] = occurrenceCount;

    emit(
      state.copyWith(
        status: BarcodeScanStatus.resolving,
        lastCode: trimmed,
        occurrenceCount: occurrenceCount,
        clearFailure: true,
        clearResolution: true,
      ),
    );

    final result = await _resolveProductCode(
      organizationId: organizationId,
      rawCode: trimmed,
    );
    switch (result) {
      case AppSuccess<ProductCodeResolution>(value: final resolution):
        emit(
          state.copyWith(
            status: _statusFor(resolution),
            resolution: resolution,
          ),
        );
      case AppFailure<ProductCodeResolution>(failure: final failure):
        emit(
          state.copyWith(status: BarcodeScanStatus.failure, failure: failure),
        );
    }
  }

  void reportPermissionDenied() {
    emit(state.copyWith(status: BarcodeScanStatus.permissionDenied));
    unawaited(
      _analyticsService.logEvent(
        AnalyticsEvents.barcodeScanPermissionDenied,
        parameters: const <String, Object?>{'source': 'camera'},
      ),
    );
  }

  void reportManualFallbackUsed() {
    unawaited(
      _analyticsService.logEvent(AnalyticsEvents.barcodeScanManualFallbackUsed),
    );
  }

  /// Clears the last resolution/failure so the seller can scan the next
  /// code without leaving the sheet — keeps [_occurrencesByCode] so a code
  /// scanned again later in the same session still counts as a repeat.
  void resetForNextScan() {
    emit(
      const BarcodeScanState().copyWith(
        status: BarcodeScanStatus.idle,
        clearFailure: true,
        clearResolution: true,
      ),
    );
  }

  BarcodeScanStatus _statusFor(ProductCodeResolution resolution) {
    return switch (resolution.status) {
      ProductCodeResolutionStatus.singleMatch => BarcodeScanStatus.resolved,
      ProductCodeResolutionStatus.multipleMatches =>
        BarcodeScanStatus.multipleMatches,
      ProductCodeResolutionStatus.notFound => BarcodeScanStatus.notFound,
    };
  }
}
