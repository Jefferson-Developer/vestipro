import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../domain/entities/line_sheet.dart';
import '../../domain/usecases/open_line_sheet_use_case.dart';
import 'line_sheet_state.dart';

final class LineSheetCubit extends Cubit<LineSheetState> {
  LineSheetCubit({
    required String organizationId,
    required String collectionId,
    required LineSheetAccessProfile profile,
    required this.openLineSheet,
    required this.startOrderForm,
    required this.analyticsService,
    String? customerId,
  }) : super(
         LineSheetState(
           organizationId: organizationId,
           collectionId: collectionId,
           profile: profile,
           customerId: customerId,
         ),
       );

  final OpenLineSheetUseCase openLineSheet;
  final StartLineSheetOrderFormUseCase startOrderForm;
  final AnalyticsService analyticsService;

  Future<void> load() async {
    emit(state.copyWith(status: LineSheetLoadStatus.loading));
    final result = await openLineSheet(
      organizationId: state.organizationId,
      collectionId: state.collectionId,
      profile: state.profile,
      customerId: state.customerId,
    );
    result.fold(
      onSuccess: (view) {
        final draftResult = startOrderForm(view);
        emit(
          draftResult.fold(
            onSuccess: (draft) => state.copyWith(
              status: LineSheetLoadStatus.ready,
              view: view,
              draft: draft,
            ),
            onFailure: (failure) => state.copyWith(
              status: LineSheetLoadStatus.failure,
              failure: failure,
            ),
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: failure is PermissionFailure
              ? LineSheetLoadStatus.forbidden
              : LineSheetLoadStatus.failure,
          failure: failure,
        ),
      ),
    );
  }

  Future<void> changeMode(LineSheetViewMode mode) async {
    if (state.viewMode == mode) return;
    emit(state.copyWith(viewMode: mode));
    if (mode == LineSheetViewMode.orderForm && state.view != null) {
      await analyticsService.logEvent(
        AnalyticsEvents.lineSheetFiltered,
        parameters: <String, Object?>{
          'line_sheet_id': state.view!.lineSheet.id,
          'filter': 'mode_order_form',
        },
      );
    }
  }

  Future<void> viewProduct(String productId) async {
    final lineSheet = state.view?.lineSheet;
    if (lineSheet == null) return;
    await analyticsService.logEvent(
      AnalyticsEvents.lineSheetProductViewed,
      parameters: <String, Object?>{
        'line_sheet_id': lineSheet.id,
        'line_sheet_version': lineSheet.version,
        'product_id': productId,
      },
    );
  }

  Future<void> changeQuantity({
    required LineSheetProductEntry entry,
    required String variantId,
    required int quantity,
  }) async {
    final draft = state.draft;
    if (draft == null) return;
    final availability = entry.availabilityByVariantId[variantId];
    if (availability == null || !availability.acceptsQuantity) return;
    final nextDraft = draft.changeQuantity(
      productId: entry.product.id,
      variantId: variantId,
      quantity: quantity,
      unitPrice: entry.unitPrice ?? 0,
    );
    emit(state.copyWith(draft: nextDraft));
    if (quantity > 0) {
      await analyticsService.logEvent(
        AnalyticsEvents.lineSheetItemAdded,
        parameters: <String, Object?>{
          'line_sheet_id': draft.lineSheetId,
          'line_sheet_version': draft.lineSheetVersion,
          'product_id': entry.product.id,
        },
      );
    }
  }
}
