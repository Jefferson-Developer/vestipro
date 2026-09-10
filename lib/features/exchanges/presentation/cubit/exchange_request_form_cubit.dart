import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../inventory/domain/usecases/get_variant_inventory_availability_use_case.dart';
import '../../../products/domain/entities/product_variant.dart';
import '../../../products/domain/usecases/list_product_variants_by_product_use_case.dart';
import '../../../products/domain/value_objects/product_variant_status.dart';
import '../../domain/entities/exchange_request_item.dart';
import '../../domain/usecases/create_exchange_request_use_case.dart';
import '../../domain/value_objects/exchange_reason_category.dart';
import 'exchange_request_form_state.dart';

/// Drives the "solicitar troca" form (TASK-200, EPIC-30) — motivo
/// categorizado obrigatório, seleção da variante de destino (mesmo produto,
/// cor/tamanho diferente) com disponibilidade em tempo real, quantidade por
/// item nunca excedendo a do pedido original (revalidado sempre
/// server-side por `createExchangeRequest`, esta camada só evita uma
/// chamada já sabidamente inválida ou uma seleção óbvia sem estoque no
/// instante da consulta).
///
/// [exchangeRequestId] is generated once, at construction, so a retried
/// submission (double tap, dropped response) always carries the very same
/// idempotency key — same precedent `ReturnRequestFormCubit.returnRequestId`
/// (TASK-199) already sets.
@injectable
final class ExchangeRequestFormCubit extends Cubit<ExchangeRequestFormState> {
  ExchangeRequestFormCubit(
    this._createExchangeRequest,
    this._listProductVariantsByProduct,
    this._getVariantInventoryAvailability,
    this._analyticsService,
  ) : exchangeRequestId = const Uuid().v4(),
      super(const ExchangeRequestFormState());

  final CreateExchangeRequestUseCase _createExchangeRequest;
  final ListProductVariantsByProductUseCase _listProductVariantsByProduct;
  final GetVariantInventoryAvailabilityUseCase _getVariantInventoryAvailability;
  final AnalyticsService _analyticsService;

  final String exchangeRequestId;

  void setQuantity(String orderItemId, int quantity) {
    final updated = Map<String, int>.from(state.selectedQuantities);
    if (quantity <= 0) {
      updated.remove(orderItemId);
    } else {
      updated[orderItemId] = quantity;
    }
    emit(
      state.copyWith(
        selectedQuantities: updated,
        fieldErrors: const <String, String>{},
        clearFailureMessage: true,
      ),
    );
  }

  /// Loads every active variant of [productId] other than
  /// [originVariantId] — the candidate destination variants for
  /// [orderItemId] (mesmo produto, cor/tamanho diferente).
  Future<void> loadDestinationVariants({
    required String organizationId,
    required String orderItemId,
    required String productId,
    required String originVariantId,
  }) async {
    emit(state.copyWith(loadingDestinationVariantsForOrderItem: orderItemId));
    final result = await _listProductVariantsByProduct(
      organizationId: organizationId,
      productId: productId,
    );
    result.fold(
      onSuccess: (variants) {
        final candidates = variants
            .where(
              (variant) =>
                  variant.status == ProductVariantStatus.active &&
                  variant.id != originVariantId,
            )
            .toList(growable: false);
        final updated = Map<String, List<ProductVariant>>.from(
          state.destinationVariantsByOrderItem,
        )..[orderItemId] = candidates;
        emit(
          state.copyWith(
            destinationVariantsByOrderItem: updated,
            clearLoadingDestinationVariantsForOrderItem: true,
          ),
        );
      },
      onFailure: (_) => emit(
        state.copyWith(clearLoadingDestinationVariantsForOrderItem: true),
      ),
    );
  }

  /// Selects [destinationVariantId] for [orderItemId] and checks its
  /// real-time sellable quantity (`tasks.md`: "já validando estoque em tempo
  /// real") — purely informative feedback: the authoritative check is
  /// always `createExchangeRequest`/`resolveExchangeRequest`'s own, re-run
  /// server-side inside a transaction.
  Future<void> selectDestinationVariant({
    required String organizationId,
    required String orderItemId,
    required String destinationVariantId,
  }) async {
    final updatedSelection = Map<String, String>.from(
      state.selectedDestinationVariantId,
    )..[orderItemId] = destinationVariantId;
    emit(
      state.copyWith(
        selectedDestinationVariantId: updatedSelection,
        checkingAvailabilityForVariant: destinationVariantId,
        fieldErrors: const <String, String>{},
      ),
    );
    final result = await _getVariantInventoryAvailability(
      organizationId: organizationId,
      variantId: destinationVariantId,
    );
    result.fold(
      onSuccess: (availability) {
        final updatedAvailability = Map<String, int>.from(
          state.destinationAvailability,
        )..[destinationVariantId] = availability.totalSellableQuantity;
        emit(
          state.copyWith(
            destinationAvailability: updatedAvailability,
            clearCheckingAvailabilityForVariant: true,
          ),
        );
      },
      onFailure: (_) =>
          emit(state.copyWith(clearCheckingAvailabilityForVariant: true)),
    );
  }

  void setReasonCategory(ExchangeReasonCategory category) {
    emit(
      state.copyWith(
        reasonCategory: category,
        fieldErrors: const <String, String>{},
        clearFailureMessage: true,
      ),
    );
  }

  void setReasonDetails(String details) {
    emit(state.copyWith(reasonDetails: details));
  }

  Future<void> submit({
    required String organizationId,
    required String companyId,
    required String userId,
    required String orderId,
  }) async {
    final reasonCategory = state.reasonCategory;
    if (reasonCategory == null) {
      emit(
        state.copyWith(
          fieldErrors: const <String, String>{
            'reasonCategory': 'Selecione o motivo da troca.',
          },
        ),
      );
      return;
    }
    if (!state.hasAnyItemSelected) {
      emit(
        state.copyWith(
          fieldErrors: const <String, String>{
            'items': 'Selecione ao menos um item para trocar.',
          },
        ),
      );
      return;
    }
    final selectedOrderItemIds = state.selectedQuantities.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList(growable: false);
    final missingDestination = selectedOrderItemIds.where(
      (orderItemId) =>
          !state.selectedDestinationVariantId.containsKey(orderItemId),
    );
    if (missingDestination.isNotEmpty) {
      emit(
        state.copyWith(
          fieldErrors: const <String, String>{
            'items': 'Selecione a variante de destino de cada item.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ExchangeRequestFormStatus.submitting,
        clearFailureMessage: true,
      ),
    );

    final items = selectedOrderItemIds
        .map(
          (orderItemId) => ExchangeRequestItemInput(
            orderItemId: orderItemId,
            destinationVariantId:
                state.selectedDestinationVariantId[orderItemId]!,
            quantity: state.selectedQuantities[orderItemId]!,
          ),
        )
        .toList(growable: false);

    final result = await _createExchangeRequest(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      orderId: orderId,
      exchangeRequestId: exchangeRequestId,
      items: items,
      reasonCategory: reasonCategory,
      reasonDetails: state.reasonDetails,
    );

    result.fold(
      onSuccess: (submissionResult) {
        emit(state.copyWith(status: ExchangeRequestFormStatus.success));
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.exchangeRequested,
            parameters: <String, Object?>{
              'organization_id': organizationId,
              'order_id': orderId,
              'reason_category': reasonCategory.code,
              'item_count': items.length,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: ExchangeRequestFormStatus.failure,
          failureMessage: failure.message,
        ),
      ),
    );
  }
}
