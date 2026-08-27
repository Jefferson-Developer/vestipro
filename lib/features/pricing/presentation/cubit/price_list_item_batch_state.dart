import '../../../../core/errors/errors.dart';
import '../../domain/entities/price_list_item.dart';

enum PriceListItemBatchLoadStatus { initial, loading, ready, failure }

enum PriceListItemBatchSaveStatus {
  idle,
  editing,
  submitting,
  success,
  failure,
  overwriteWarning,
}

final class PriceListItemBatchState {
  const PriceListItemBatchState({
    this.loadStatus = PriceListItemBatchLoadStatus.initial,
    this.saveStatus = PriceListItemBatchSaveStatus.idle,
    this.organizationId = '',
    this.companyId = '',
    this.priceListId = '',
    this.userId = '',
    this.productId = '',
    this.basePriceInput = '',
    this.variantExceptionsInput = '',
    this.items = const <PriceListItem>[],
    this.fieldErrors = const <String, String>{},
    this.failure,
  });

  final PriceListItemBatchLoadStatus loadStatus;
  final PriceListItemBatchSaveStatus saveStatus;
  final String organizationId;
  final String companyId;
  final String priceListId;
  final String userId;
  final String productId;
  final String basePriceInput;
  final String variantExceptionsInput;
  final List<PriceListItem> items;
  final Map<String, String> fieldErrors;
  final Failure? failure;

  bool get isBusy =>
      loadStatus == PriceListItemBatchLoadStatus.loading ||
      saveStatus == PriceListItemBatchSaveStatus.submitting;

  PriceListItemBatchState copyWith({
    PriceListItemBatchLoadStatus? loadStatus,
    PriceListItemBatchSaveStatus? saveStatus,
    String? organizationId,
    String? companyId,
    String? priceListId,
    String? userId,
    String? productId,
    String? basePriceInput,
    String? variantExceptionsInput,
    List<PriceListItem>? items,
    Map<String, String>? fieldErrors,
    Failure? failure,
    bool clearFailure = false,
    bool clearFieldErrors = false,
  }) {
    return PriceListItemBatchState(
      loadStatus: loadStatus ?? this.loadStatus,
      saveStatus: saveStatus ?? this.saveStatus,
      organizationId: organizationId ?? this.organizationId,
      companyId: companyId ?? this.companyId,
      priceListId: priceListId ?? this.priceListId,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      basePriceInput: basePriceInput ?? this.basePriceInput,
      variantExceptionsInput:
          variantExceptionsInput ?? this.variantExceptionsInput,
      items: items ?? this.items,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
