import 'dart:async';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/storage/storage.dart';
import '../../domain/entities/return_request_item.dart';
import '../../domain/usecases/create_return_request_use_case.dart';
import '../../domain/value_objects/return_reason_category.dart';
import 'return_request_form_state.dart';

/// Drives the "solicitar devolução" form (TASK-199, EPIC-30) — motivo
/// categorizado obrigatório, quantidade por item nunca excedendo a do
/// pedido original (revalidado sempre server-side por `createReturnRequest`,
/// esta camada só evita uma chamada já sabidamente inválida).
///
/// [returnRequestId] is generated once, at construction, so an evidence
/// photo can be uploaded to its final Storage path
/// (`StoragePaths.returnRequestEvidence`) before `createReturnRequest` is
/// ever called — both must agree on the same id.
@injectable
final class ReturnRequestFormCubit extends Cubit<ReturnRequestFormState> {
  ReturnRequestFormCubit(
    this._createReturnRequest,
    this._analyticsService,
    this._storageDataSource,
    this._imageUploadCompressor,
  ) : returnRequestId = const Uuid().v4(),
      super(const ReturnRequestFormState());

  final CreateReturnRequestUseCase _createReturnRequest;
  final AnalyticsService _analyticsService;
  final StorageDataSource _storageDataSource;
  final ImageUploadCompressor _imageUploadCompressor;

  /// Client-generated idempotency key/document id — stable for this cubit's
  /// whole lifetime (one screen instance == one devolução intent).
  final String returnRequestId;

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

  void setReasonCategory(ReturnReasonCategory category) {
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

  Future<void> uploadEvidence({
    required String organizationId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    emit(state.copyWith(isUploadingEvidence: true, clearFailureMessage: true));
    try {
      final compressed = await _imageUploadCompressor.compressForUpload(bytes);
      final path = StoragePaths.returnRequestEvidence(
        organizationId: organizationId,
        returnRequestId: returnRequestId,
        fileName: fileName,
      );
      final url = await _storageDataSource.uploadFile(
        path: path,
        bytes: compressed,
        contentType: 'image/jpeg',
      );
      emit(
        state.copyWith(
          evidenceUrls: <String>[...state.evidenceUrls, url],
          isUploadingEvidence: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isUploadingEvidence: false,
          failureMessage: 'Não foi possível enviar a foto. Tente novamente.',
        ),
      );
    }
  }

  void removeEvidenceUrl(String url) {
    emit(
      state.copyWith(
        evidenceUrls: state.evidenceUrls
            .where((item) => item != url)
            .toList(growable: false),
      ),
    );
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
            'reasonCategory': 'Selecione o motivo da devolução.',
          },
        ),
      );
      return;
    }
    if (!state.hasAnyItemSelected) {
      emit(
        state.copyWith(
          fieldErrors: const <String, String>{
            'items': 'Selecione ao menos um item para devolver.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ReturnRequestFormStatus.submitting,
        clearFailureMessage: true,
      ),
    );

    final items = state.selectedQuantities.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => ReturnRequestItemInput(
            orderItemId: entry.key,
            quantity: entry.value,
          ),
        )
        .toList(growable: false);

    final result = await _createReturnRequest(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      orderId: orderId,
      returnRequestId: returnRequestId,
      items: items,
      reasonCategory: reasonCategory,
      reasonDetails: state.reasonDetails,
      evidenceUrls: state.evidenceUrls,
    );

    result.fold(
      onSuccess: (submissionResult) {
        emit(state.copyWith(status: ReturnRequestFormStatus.success));
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.returnRequested,
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
          status: ReturnRequestFormStatus.failure,
          failureMessage: failure.message,
        ),
      ),
    );
  }
}
