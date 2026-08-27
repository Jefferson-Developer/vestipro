import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/price_list_item.dart';
import '../../domain/repositories/price_list_item_repository.dart';
import '../../domain/usecases/upsert_price_list_items_batch_use_case.dart';
import 'price_list_item_batch_state.dart';

@injectable
final class PriceListItemBatchCubit extends Cubit<PriceListItemBatchState> {
  PriceListItemBatchCubit(this._repository, this._upsertBatch)
    : super(const PriceListItemBatchState());

  final PriceListItemRepository _repository;
  final UpsertPriceListItemsBatchUseCase _upsertBatch;

  Future<void> load({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required String userId,
  }) async {
    emit(
      state.copyWith(
        loadStatus: PriceListItemBatchLoadStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        priceListId: priceListId,
        userId: userId,
        clearFailure: true,
      ),
    );
    final result = await _repository.listByPriceList(
      organizationId: organizationId,
      companyId: companyId,
      priceListId: priceListId,
    );
    switch (result) {
      case AppSuccess<List<PriceListItem>>(value: final items):
        emit(
          state.copyWith(
            loadStatus: PriceListItemBatchLoadStatus.ready,
            items: items,
          ),
        );
      case AppFailure<List<PriceListItem>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: PriceListItemBatchLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void updateForm({
    String? productId,
    String? basePriceInput,
    String? variantExceptionsInput,
  }) {
    emit(
      state.copyWith(
        saveStatus: PriceListItemBatchSaveStatus.editing,
        productId: productId ?? state.productId,
        basePriceInput: basePriceInput ?? state.basePriceInput,
        variantExceptionsInput:
            variantExceptionsInput ?? state.variantExceptionsInput,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> submit({bool confirmOverwrite = false}) async {
    emit(
      state.copyWith(
        saveStatus: PriceListItemBatchSaveStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );

    final inputs = <PriceListItemInput>[];
    final basePrice = _parsePrice(state.basePriceInput);
    if (basePrice != null) {
      inputs.add(
        PriceListItemInput(productId: state.productId, price: basePrice),
      );
    }
    inputs.addAll(_parseVariantExceptions());

    final result = await _upsertBatch(
      organizationId: state.organizationId,
      companyId: state.companyId,
      priceListId: state.priceListId,
      updatedBy: state.userId,
      items: inputs,
      confirmOverwrite: confirmOverwrite,
    );

    switch (result) {
      case AppSuccess<List<PriceListItem>>():
        await load(
          organizationId: state.organizationId,
          companyId: state.companyId,
          priceListId: state.priceListId,
          userId: state.userId,
        );
        emit(
          state.copyWith(
            saveStatus: PriceListItemBatchSaveStatus.success,
            productId: '',
            basePriceInput: '',
            variantExceptionsInput: '',
            clearFieldErrors: true,
            clearFailure: true,
          ),
        );
      case AppFailure<List<PriceListItem>>(failure: final failure):
        if (failure is ConflictFailure &&
            failure.code == 'price_list_item_overwrite_confirmation_required') {
          emit(
            state.copyWith(
              saveStatus: PriceListItemBatchSaveStatus.overwriteWarning,
              failure: failure,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            saveStatus: PriceListItemBatchSaveStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }

  double? _parsePrice(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  List<PriceListItemInput> _parseVariantExceptions() {
    final lines = state.variantExceptionsInput
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    final items = <PriceListItemInput>[];
    for (final line in lines) {
      final parts = line.split('=');
      final variantId = parts.first.trim();
      final price = parts.length < 2 ? null : _parsePrice(parts.last);
      items.add(
        PriceListItemInput(
          productId: state.productId,
          variantId: variantId,
          price: price ?? double.nan,
        ),
      );
    }
    return items;
  }
}
