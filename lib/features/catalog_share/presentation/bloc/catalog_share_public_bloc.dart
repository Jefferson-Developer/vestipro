import 'dart:async' show unawaited;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_share_preview.dart';
import '../../domain/usecases/preview_catalog_share_use_case.dart';
import '../../domain/usecases/register_catalog_share_open_use_case.dart';
import '../../domain/value_objects/catalog_share_outcome.dart';
import '../../domain/value_objects/catalog_share_scope.dart';
import 'catalog_share_public_event.dart';
import 'catalog_share_public_state.dart';

/// Orchestrates `CatalogSharePublicPage` (TASK-081, EPIC-10): the
/// public, unauthenticated screen a customer opens from a share link — no
/// organization/session context exists yet, everything is resolved purely
/// from the token in the URL.
@injectable
final class CatalogSharePublicBloc
    extends Bloc<CatalogSharePublicEvent, CatalogSharePublicState> {
  CatalogSharePublicBloc({
    required this.previewCatalogShare,
    required this.registerCatalogShareOpen,
    required this.analyticsService,
  }) : super(const CatalogSharePublicState()) {
    on<CatalogSharePublicStarted>(_onStarted, transformer: restartable());
  }

  final PreviewCatalogShareUseCase previewCatalogShare;
  final RegisterCatalogShareOpenUseCase registerCatalogShareOpen;
  final AnalyticsService analyticsService;

  Future<void> _onStarted(
    CatalogSharePublicStarted event,
    Emitter<CatalogSharePublicState> emit,
  ) async {
    emit(
      CatalogSharePublicState(
        status: CatalogSharePublicStatus.loading,
        token: event.token,
      ),
    );

    final result = await previewCatalogShare(token: event.token);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<CatalogSharePreview>(value: final preview):
        if (preview.outcome == CatalogShareOutcome.valid) {
          emit(
            state.copyWith(
              status: CatalogSharePublicStatus.valid,
              preview: preview,
            ),
          );
          await analyticsService.logEvent(
            AnalyticsEvents.catalogShareOpened,
            parameters: <String, Object?>{
              'scope': preview.scope?.code,
              'items_count': preview.items.length,
            },
          );
          // Fire-and-forget by design — see `RegisterCatalogShareOpenUseCase`/
          // `registerCatalogShareOpen`'s own docs: this must never delay or
          // affect what the visitor already sees.
          unawaited(registerCatalogShareOpen(token: event.token));
        } else {
          emit(
            state.copyWith(
              status: CatalogSharePublicStatus.unavailable,
              unavailableReason: preview.outcome,
            ),
          );
        }
      case AppFailure<CatalogSharePreview>(failure: final failure):
        emit(
          state.copyWith(
            status: CatalogSharePublicStatus.error,
            failure: failure,
          ),
        );
    }
  }
}
