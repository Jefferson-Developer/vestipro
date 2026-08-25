import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/commercial_size_grid_draft.dart';
import '../../domain/entities/variant_availability.dart';
import '../../domain/entities/variant_availability_snapshot.dart';
import '../../domain/usecases/get_commercial_size_grid_draft_use_case.dart';
import '../../domain/usecases/get_variant_availability_use_case.dart';
import '../../domain/usecases/save_commercial_size_grid_draft_use_case.dart';
import 'commercial_size_grid_event.dart';
import 'commercial_size_grid_state.dart';

@injectable
final class CommercialSizeGridBloc
    extends Bloc<CommercialSizeGridEvent, CommercialSizeGridState> {
  CommercialSizeGridBloc({
    required this.getDraft,
    required this.saveDraft,
    required this.getAvailability,
  }) : super(const CommercialSizeGridState()) {
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
  final GetVariantAvailabilityUseCase getAvailability;

  Future<void> _onStarted(
    CommercialSizeGridStarted event,
    Emitter<CommercialSizeGridState> emit,
  ) async {
    final variants = event.variants
        .where(
          (variant) =>
              variant.organizationId == event.product.organizationId &&
              variant.productId == event.product.id,
        )
        .toList(growable: false);

    emit(
      state.copyWith(
        loadStatus: CommercialSizeGridLoadStatus.loading,
        product: event.product,
        colors: event.colors,
        sizeGridTemplate: event.sizeGridTemplate,
        variants: variants,
        availabilityByVariantId: const <String, VariantAvailability>{},
        clearFailure: true,
      ),
    );

    final draftResult = await getDraft(
      organizationId: event.product.organizationId,
      productId: event.product.id,
    );
    if (emit.isDone) return;
    switch (draftResult) {
      case AppSuccess<CommercialSizeGridDraft?>(value: final draft):
        final availabilityResult = await getAvailability(
          organizationId: event.product.organizationId,
          variantIds: variants.map((variant) => variant.id),
        );
        if (emit.isDone) return;
        switch (availabilityResult) {
          case AppSuccess<VariantAvailabilitySnapshot>(value: final snapshot):
            emit(
              state.copyWith(
                loadStatus: CommercialSizeGridLoadStatus.ready,
                saveStatus: CommercialSizeGridSaveStatus.idle,
                availabilityByVariantId: snapshot.byVariantId,
                quantitiesByVariantId: _filteredQuantities(
                  draft?.quantitiesByVariantId ?? const <String, int>{},
                  availabilityByVariantId: snapshot.byVariantId,
                ),
                clearFailure: true,
              ),
            );
          case AppFailure<VariantAvailabilitySnapshot>(failure: final failure):
            emit(
              state.copyWith(
                loadStatus: CommercialSizeGridLoadStatus.failure,
                failure: failure,
              ),
            );
        }
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

  Map<String, int> _filteredQuantities(
    Map<String, int> draftQuantities, {
    Map<String, VariantAvailability>? availabilityByVariantId,
  }) {
    final validVariantIds = state.variants
        .where((variant) {
          final availability =
              availabilityByVariantId?[variant.id] ??
              state.availabilityForVariant(variant);
          return availability.acceptsQuantity;
        })
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
