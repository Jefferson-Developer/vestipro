import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../domain/usecases/backorder_use_cases.dart';
import 'backorder_queue_state.dart';

/// Drives [BackorderQueuePage] (TASK-215, EPIC-32): watches the priorized
/// fila de atendimento and the "aguardando aprovação" inbox simultaneously,
/// and lets an authorized gestor decide/cancel/convert a backorder.
@injectable
final class BackorderQueueCubit extends Cubit<BackorderQueueState> {
  BackorderQueueCubit(
    this._watchQueue,
    this._watchAwaitingApproval,
    this._decideApproval,
    this._cancelRequest,
    this._convertToOrder,
    this._analyticsService,
  ) : super(const BackorderQueueState());

  final WatchBackorderQueueUseCase _watchQueue;
  final WatchBackordersAwaitingApprovalUseCase _watchAwaitingApproval;
  final DecideBackorderApprovalUseCase _decideApproval;
  final CancelBackorderRequestUseCase _cancelRequest;
  final ConvertBackorderToOrderUseCase _convertToOrder;
  final AnalyticsService _analyticsService;

  StreamSubscription<dynamic>? _queueSubscription;
  StreamSubscription<dynamic>? _awaitingApprovalSubscription;
  String? _organizationId;

  Future<void> watch({required String organizationId}) async {
    _organizationId = organizationId;
    emit(state.copyWith(status: BackorderQueueStatus.loading));

    await _queueSubscription?.cancel();
    _queueSubscription = _watchQueue(organizationId: organizationId).listen((
      result,
    ) {
      result.fold(
        onSuccess: (queue) => emit(
          state.copyWith(
            status: BackorderQueueStatus.ready,
            queue: queue,
            clearFailureMessage: true,
          ),
        ),
        onFailure: (failure) => emit(
          state.copyWith(
            status: BackorderQueueStatus.failure,
            failureMessage: failure.message,
          ),
        ),
      );
    });

    await _awaitingApprovalSubscription?.cancel();
    _awaitingApprovalSubscription =
        _watchAwaitingApproval(organizationId: organizationId).listen((result) {
          result.fold(
            onSuccess: (awaitingApproval) =>
                emit(state.copyWith(awaitingApproval: awaitingApproval)),
            onFailure: (_) {},
          );
        });
  }

  Future<void> decide({
    required String backorderId,
    required bool approve,
    String? note,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    emit(
      state.copyWith(
        processingBackorderId: backorderId,
        clearActionFailureMessage: true,
      ),
    );

    final result = await _decideApproval(
      organizationId: organizationId,
      backorderId: backorderId,
      approve: approve,
      note: note,
    );

    result.fold(
      onSuccess: (_) {
        emit(
          state.copyWith(
            clearProcessingBackorderId: true,
            lastActionBackorderId: backorderId,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            approve
                ? AnalyticsEvents.backorderApproved
                : AnalyticsEvents.backorderRejected,
            parameters: <String, Object?>{'backorder_id': backorderId},
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          clearProcessingBackorderId: true,
          actionFailureMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> cancel({required String backorderId, String? reason}) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    emit(
      state.copyWith(
        processingBackorderId: backorderId,
        clearActionFailureMessage: true,
      ),
    );

    final result = await _cancelRequest(
      organizationId: organizationId,
      backorderId: backorderId,
      reason: reason,
    );

    result.fold(
      onSuccess: (_) {
        emit(
          state.copyWith(
            clearProcessingBackorderId: true,
            lastActionBackorderId: backorderId,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.backorderCancelled,
            parameters: <String, Object?>{'backorder_id': backorderId},
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          clearProcessingBackorderId: true,
          actionFailureMessage: failure.message,
        ),
      ),
    );
  }

  Future<void> convert({
    required String backorderId,
    required String orderId,
  }) async {
    final organizationId = _organizationId;
    if (organizationId == null) return;

    emit(
      state.copyWith(
        processingBackorderId: backorderId,
        clearActionFailureMessage: true,
      ),
    );

    final result = await _convertToOrder(
      organizationId: organizationId,
      backorderId: backorderId,
      orderId: orderId,
    );

    result.fold(
      onSuccess: (_) {
        emit(
          state.copyWith(
            clearProcessingBackorderId: true,
            lastActionBackorderId: backorderId,
          ),
        );
        unawaited(
          _analyticsService.logEvent(
            AnalyticsEvents.backorderConverted,
            parameters: <String, Object?>{
              'backorder_id': backorderId,
              'order_id': orderId,
            },
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          clearProcessingBackorderId: true,
          actionFailureMessage: failure.message,
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_queueSubscription?.cancel());
    unawaited(_awaitingApprovalSubscription?.cancel());
    return super.close();
  }
}
