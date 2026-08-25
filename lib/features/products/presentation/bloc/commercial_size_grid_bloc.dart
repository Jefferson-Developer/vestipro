import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/commercial_size_grid_draft.dart';
import '../../domain/usecases/get_commercial_size_grid_draft_use_case.dart';
import '../../domain/usecases/save_commercial_size_grid_draft_use_case.dart';
import 'commercial_size_grid_event.dart';
import 'commercial_size_grid_state.dart';

@injectable
final class CommercialSizeGridBloc
    extends Bloc<CommercialSizeGridEvent, CommercialSizeGridState> {
  CommercialSizeGridBloc({required this.getDraft, required this.saveDraft})
    : super(const CommercialSizeGridState()) {
    on<CommercialSizeGridStarted>(_onStarted, transformer: restartable());
    on<CommercialSizeGridQuantityChanged>(
      _onQuantityChanged,
      transformer: sequential(),
    );
    on<CommercialSizeGridConnectivityChanged>(
      _onConnectivityChanged,
      transformer: sequential(),
    );
  }

  final GetCommercialSizeGridDraftUseCase getDraft;
  final SaveCommercialSizeGridDraftUseCase saveDraft;

  Future<void> _onStarted(
    CommercialSizeGridStarted event,
    Emitter<CommercialSizeGridState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: CommercialSizeGridLoadStatus.loading,
        product: event.product,
        colors: event.colors,
        sizeGridTemplate: event.sizeGridTemplate,
        variants: event.variants
            .where(
              (variant) =>
                  variant.organizationId == event.product.organizationId &&
                  variant.productId == event.product.id,
            )
            .toList(growable: false),
        availabilityByVariantId: event.availabilityByVariantId,
        clearFailure: true,
      ),
    );

    final result = await getDraft(
      organizationId: event.product.organizationId,
      productId: event.product.id,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<CommercialSizeGridDraft?>(value: final draft):
        emit(
          state.copyWith(
            loadStatus: CommercialSizeGridLoadStatus.ready,
            saveStatus: CommercialSizeGridSaveStatus.idle,
            quantitiesByVariantId: _filteredQuantities(
              draft?.quantitiesByVariantId ?? const <String, int>{},
            ),
            clearFailure: true,
          ),
        );
      case AppFailure<CommercialSizeGridDraft?>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CommercialSizeGridLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _onQuantityChanged(
    CommercialSizeGridQuantityChanged event,
    Emitter<CommercialSizeGridState> emit,
  ) async {
    final variant = state.variantForCell(
      colorId: event.colorId,
      sizeId: event.sizeId,
    );
    final product = state.product;
    if (variant == null ||
        product == null ||
        !state.isVariantEditable(variant)) {
      return;
    }

    final nextQuantity = event.quantity < 0 ? 0 : event.quantity;
    final nextQuantities = Map<String, int>.of(state.quantitiesByVariantId);
    if (nextQuantity == 0) {
      nextQuantities.remove(variant.id);
    } else {
      nextQuantities[variant.id] = nextQuantity;
    }

    emit(
      state.copyWith(
        saveStatus: CommercialSizeGridSaveStatus.saving,
        quantitiesByVariantId: Map<String, int>.unmodifiable(nextQuantities),
        clearFailure: true,
      ),
    );

    final result = await saveDraft(
      draft: CommercialSizeGridDraft(
        organizationId: product.organizationId,
        productId: product.id,
        quantitiesByVariantId: Map<String, int>.unmodifiable(nextQuantities),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<CommercialSizeGridDraft>():
        emit(state.copyWith(saveStatus: CommercialSizeGridSaveStatus.saved));
      case AppFailure<CommercialSizeGridDraft>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: CommercialSizeGridSaveStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onConnectivityChanged(
    CommercialSizeGridConnectivityChanged event,
    Emitter<CommercialSizeGridState> emit,
  ) {
    emit(state.copyWith(isOnline: event.isOnline));
  }

  Map<String, int> _filteredQuantities(Map<String, int> draftQuantities) {
    final validVariantIds = state.variants
        .where(state.isVariantEditable)
        .map((variant) => variant.id)
        .toSet();
    return Map<String, int>.unmodifiable(
      Map<String, int>.fromEntries(
        draftQuantities.entries.where(
          (entry) => validVariantIds.contains(entry.key) && entry.value > 0,
        ),
      ),
    );
  }
}
