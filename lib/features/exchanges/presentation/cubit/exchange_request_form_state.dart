import '../../../products/domain/entities/product_variant.dart';
import '../../domain/value_objects/exchange_reason_category.dart';

enum ExchangeRequestFormStatus { idle, submitting, success, failure }

final class ExchangeRequestFormState {
  const ExchangeRequestFormState({
    this.status = ExchangeRequestFormStatus.idle,
    this.selectedQuantities = const <String, int>{},
    this.selectedDestinationVariantId = const <String, String>{},
    this.destinationVariantsByOrderItem =
        const <String, List<ProductVariant>>{},
    this.destinationAvailability = const <String, int>{},
    this.loadingDestinationVariantsForOrderItem,
    this.checkingAvailabilityForVariant,
    this.reasonCategory,
    this.reasonDetails,
    this.failureMessage,
    this.fieldErrors = const <String, String>{},
  });

  final ExchangeRequestFormStatus status;

  /// `orderItemId -> quantidade a trocar` — apenas itens com quantidade `> 0`
  /// e com variante de destino selecionada são de fato enviados na
  /// solicitação.
  final Map<String, int> selectedQuantities;

  /// `orderItemId -> id da variante de destino escolhida` — nova cor/tamanho
  /// do mesmo produto.
  final Map<String, String> selectedDestinationVariantId;

  /// `orderItemId -> variantes ativas disponíveis do mesmo produto` (exceto a
  /// variante original do próprio item), carregadas sob demanda.
  final Map<String, List<ProductVariant>> destinationVariantsByOrderItem;

  /// `variantId -> saldo total sellable em tempo real` (feedback de UI
  /// apenas — a checagem que realmente autoriza a troca é sempre
  /// revalidada, com autoridade final, por `createExchangeRequest`/
  /// `resolveExchangeRequest`).
  final Map<String, int> destinationAvailability;

  final String? loadingDestinationVariantsForOrderItem;
  final String? checkingAvailabilityForVariant;
  final ExchangeReasonCategory? reasonCategory;
  final String? reasonDetails;
  final String? failureMessage;
  final Map<String, String> fieldErrors;

  bool get hasAnyItemSelected =>
      selectedQuantities.values.any((quantity) => quantity > 0);

  ExchangeRequestFormState copyWith({
    ExchangeRequestFormStatus? status,
    Map<String, int>? selectedQuantities,
    Map<String, String>? selectedDestinationVariantId,
    Map<String, List<ProductVariant>>? destinationVariantsByOrderItem,
    Map<String, int>? destinationAvailability,
    String? loadingDestinationVariantsForOrderItem,
    bool clearLoadingDestinationVariantsForOrderItem = false,
    String? checkingAvailabilityForVariant,
    bool clearCheckingAvailabilityForVariant = false,
    ExchangeReasonCategory? reasonCategory,
    String? reasonDetails,
    String? failureMessage,
    bool clearFailureMessage = false,
    Map<String, String>? fieldErrors,
  }) {
    return ExchangeRequestFormState(
      status: status ?? this.status,
      selectedQuantities: selectedQuantities ?? this.selectedQuantities,
      selectedDestinationVariantId:
          selectedDestinationVariantId ?? this.selectedDestinationVariantId,
      destinationVariantsByOrderItem:
          destinationVariantsByOrderItem ?? this.destinationVariantsByOrderItem,
      destinationAvailability:
          destinationAvailability ?? this.destinationAvailability,
      loadingDestinationVariantsForOrderItem:
          clearLoadingDestinationVariantsForOrderItem
          ? null
          : (loadingDestinationVariantsForOrderItem ??
                this.loadingDestinationVariantsForOrderItem),
      checkingAvailabilityForVariant: clearCheckingAvailabilityForVariant
          ? null
          : (checkingAvailabilityForVariant ??
                this.checkingAvailabilityForVariant),
      reasonCategory: reasonCategory ?? this.reasonCategory,
      reasonDetails: reasonDetails ?? this.reasonDetails,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
