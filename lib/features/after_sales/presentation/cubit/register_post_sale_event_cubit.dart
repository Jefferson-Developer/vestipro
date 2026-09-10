import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/analytics/analytics.dart';
import '../../domain/usecases/register_post_sale_event_use_case.dart';
import '../../domain/value_objects/post_sale_event_type.dart';
import 'register_post_sale_event_state.dart';

/// Drives the "registrar evento de pós-venda" form (TASK-201, EPIC-30) —
/// tipo restrito aos marcos manuais, descrição obrigatória apenas para
/// "problema reportado" (revalidado sempre server-side por
/// `registerPostSaleEvent`, esta camada só evita uma chamada já sabidamente
/// inválida).
///
/// [eventId] is generated once, at construction, so a retried submit (double
/// tap, retry after a dropped response) always carries the very same id,
/// same precedent `ReturnRequestFormCubit`'s own `returnRequestId` already
/// sets.
@injectable
final class RegisterPostSaleEventCubit
    extends Cubit<RegisterPostSaleEventState> {
  RegisterPostSaleEventCubit(
    this._registerPostSaleEvent,
    this._analyticsService,
  ) : eventId = const Uuid().v4(),
      super(const RegisterPostSaleEventState());

  final RegisterPostSaleEventUseCase _registerPostSaleEvent;
  final AnalyticsService _analyticsService;

  /// Client-generated idempotency key/document id — stable for this cubit's
  /// whole lifetime (one screen instance == one registro intent).
  final String eventId;

  void setType(PostSaleEventType type) {
    emit(
      state.copyWith(
        type: type,
        fieldErrors: const <String, String>{},
        clearFailureMessage: true,
      ),
    );
  }

  void setDescription(String description) {
    emit(state.copyWith(description: description));
  }

  Future<void> submit({
    required String organizationId,
    required String companyId,
    required String userId,
    required String orderId,
  }) async {
    if (state.type.requiresDescription &&
        (state.description == null || state.description!.trim().isEmpty)) {
      emit(
        state.copyWith(
          fieldErrors: const <String, String>{
            'description': 'Descreva o problema reportado.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: RegisterPostSaleEventStatus.submitting,
        clearFailureMessage: true,
      ),
    );

    final result = await _registerPostSaleEvent(
      organizationId: organizationId,
      companyId: companyId,
      userId: userId,
      orderId: orderId,
      eventId: eventId,
      type: state.type,
      description: state.description,
    );

    result.fold(
      onSuccess: (submissionResult) {
        emit(state.copyWith(status: RegisterPostSaleEventStatus.success));
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.postSaleEventRegistered,
            parameters: <String, Object?>{
              'organization_id': organizationId,
              'order_id': orderId,
              'event_type': state.type.code,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: RegisterPostSaleEventStatus.failure,
          failureMessage: failure.message,
        ),
      ),
    );
  }
}
