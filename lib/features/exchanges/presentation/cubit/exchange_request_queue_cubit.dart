import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../domain/entities/exchange_request.dart';
import '../../domain/usecases/resolve_exchange_request_use_case.dart';
import '../../domain/usecases/watch_exchange_request_queue_use_case.dart';
import '../../domain/value_objects/exchange_request_status.dart';
import 'exchange_request_queue_state.dart';

/// Drives the troca analysis queue (TASK-200, EPIC-30) — every
/// [ExchangeRequestStatus.requested] request the caller may decide
/// ([WatchExchangeRequestQueueUseCase]'s own visibility scope, reused from
/// pedidos, TASK-102), combined with [ResolveExchangeRequestUseCase] for the
/// aprovar/rejeitar action itself.
@injectable
final class ExchangeRequestQueueCubit extends Cubit<ExchangeRequestQueueState> {
  ExchangeRequestQueueCubit(
    this._watchQueue,
    this._resolveExchangeRequest,
    this._analyticsService,
  ) : super(const ExchangeRequestQueueState());

  final WatchExchangeRequestQueueUseCase _watchQueue;
  final ResolveExchangeRequestUseCase _resolveExchangeRequest;
  final AnalyticsService _analyticsService;

  StreamSubscription<Object?>? _subscription;
  String _organizationId = '';
  String _companyId = '';
  String _userId = '';

  Future<void> watch({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    _organizationId = organizationId;
    _companyId = companyId;
    _userId = userId;
    await _subscription?.cancel();
    emit(
      state.copyWith(
        status: ExchangeRequestQueueStatus.loading,
        clearFailureMessage: true,
      ),
    );
    _subscription =
        _watchQueue(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ).listen((result) {
          result.fold(
            onSuccess: (exchangeRequests) => emit(
              state.copyWith(
                status: exchangeRequests.isEmpty
                    ? ExchangeRequestQueueStatus.empty
                    : ExchangeRequestQueueStatus.ready,
                exchangeRequests: exchangeRequests,
              ),
            ),
            onFailure: (failure) => emit(
              state.copyWith(
                status: ExchangeRequestQueueStatus.error,
                failureMessage: failure.message,
              ),
            ),
          );
        });
  }

  Future<void> decide({
    required ExchangeRequest exchangeRequest,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) async {
    emit(
      state.copyWith(
        decisionStatus: ExchangeRequestDecisionStatus.deciding,
        decidingExchangeRequestId: exchangeRequest.id,
        clearDecisionFailureMessage: true,
      ),
    );
    final result = await _resolveExchangeRequest(
      organizationId: _organizationId,
      companyId: _companyId,
      userId: _userId,
      exchangeRequestId: exchangeRequest.id,
      decision: decision,
      reason: reason,
    );
    result.fold(
      onSuccess: (decisionResult) {
        emit(
          state.copyWith(
            decisionStatus: ExchangeRequestDecisionStatus.success,
            clearDecidingExchangeRequestId: true,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            decision == ExchangeRequestDecisionValue.approved
                ? AnalyticsEvents.exchangeApproved
                : AnalyticsEvents.exchangeRejected,
            parameters: <String, Object?>{
              'organization_id': _organizationId,
              'order_id': exchangeRequest.orderId,
              if (decisionResult.priceDifferenceAmount != null)
                'price_difference_amount': decisionResult.priceDifferenceAmount,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          decisionStatus: ExchangeRequestDecisionStatus.failure,
          decisionFailureMessage: failure.message,
          clearDecidingExchangeRequestId: true,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
