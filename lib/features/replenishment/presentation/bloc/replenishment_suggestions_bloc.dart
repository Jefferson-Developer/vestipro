import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/replenishment_decision_result.dart';
import '../../domain/entities/replenishment_suggestion.dart';
import '../../domain/entities/replenishment_suggestion_page.dart';
import '../../domain/usecases/decide_replenishment_suggestion_use_case.dart';
import '../../domain/usecases/list_replenishment_suggestions_use_case.dart';
import 'replenishment_suggestions_event.dart';
import 'replenishment_suggestions_state.dart';

/// Drives the sugestões de reposição screen (TASK-184, EPIC-27) — combines
/// [ListReplenishmentSuggestionsUseCase] (paginated listing, with
/// status/warehouse filters) with
/// [DecideReplenishmentSuggestionUseCase] for the aceitar/ajustar/descartar
/// action, same "one Bloc, list + decide" shape [OrderApprovalQueueBloc]
/// already sets for the sibling pedidos approval queue.
@injectable
final class ReplenishmentSuggestionsBloc
    extends Bloc<ReplenishmentSuggestionsEvent, ReplenishmentSuggestionsState> {
  ReplenishmentSuggestionsBloc({
    required this.listSuggestions,
    required this.decideSuggestion,
  }) : super(const ReplenishmentSuggestionsState()) {
    on<ReplenishmentSuggestionsStarted>(_onStarted, transformer: restartable());
    on<ReplenishmentSuggestionsRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<ReplenishmentSuggestionsNextPageRequested>(_onNextPageRequested);
    on<ReplenishmentSuggestionsFiltersApplied>(
      _onFiltersApplied,
      transformer: restartable(),
    );
    on<ReplenishmentSuggestionsFiltersCleared>(
      _onFiltersCleared,
      transformer: restartable(),
    );
    on<ReplenishmentSuggestionsDecided>(_onDecided);
  }

  final ListReplenishmentSuggestionsUseCase listSuggestions;
  final DecideReplenishmentSuggestionUseCase decideSuggestion;

  int _requestToken = 0;

  Future<void> _onStarted(
    ReplenishmentSuggestionsStarted event,
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    emit(
      ReplenishmentSuggestionsState(
        loadStatus: ReplenishmentSuggestionsLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        warehouseId: event.initialWarehouseId?.trim() ?? '',
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onRefreshRequested(
    ReplenishmentSuggestionsRefreshRequested event,
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: ReplenishmentSuggestionsLoadStatus.loading,
        suggestions: const <ReplenishmentSuggestion>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onNextPageRequested(
    ReplenishmentSuggestionsNextPageRequested event,
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isInitialLoading) {
      return;
    }
    final requestToken = ++_requestToken;
    emit(state.copyWith(isLoadingMore: true, clearFailure: true));

    final result = await listSuggestions(
      organizationId: state.organizationId,
      requestedByUserId: state.userId,
      limit: kReplenishmentSuggestionsPageSize,
      before: state.nextCursor,
      status: state.status,
      warehouseId: state.warehouseId,
    );
    if (emit.isDone || requestToken != _requestToken) return;

    switch (result) {
      case AppSuccess<ReplenishmentSuggestionPage>(value: final page):
        final seenIds = state.suggestions.map((item) => item.id).toSet();
        final merged = <ReplenishmentSuggestion>[
          ...state.suggestions,
          for (final item in page.suggestions)
            if (seenIds.add(item.id)) item,
        ];
        emit(
          state.copyWith(
            loadStatus: ReplenishmentSuggestionsLoadStatus.ready,
            suggestions: merged,
            hasMore: page.hasMore,
            isLoadingMore: false,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            clearFailure: true,
          ),
        );
      case AppFailure<ReplenishmentSuggestionPage>(failure: final failure):
        emit(state.copyWith(isLoadingMore: false, failure: failure));
    }
  }

  Future<void> _onFiltersApplied(
    ReplenishmentSuggestionsFiltersApplied event,
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: ReplenishmentSuggestionsLoadStatus.loading,
        suggestions: const <ReplenishmentSuggestion>[],
        status: event.status,
        clearStatus: event.status == null,
        warehouseId: event.warehouseId.trim(),
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersCleared(
    ReplenishmentSuggestionsFiltersCleared event,
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: ReplenishmentSuggestionsLoadStatus.loading,
        suggestions: const <ReplenishmentSuggestion>[],
        clearStatus: true,
        clearWarehouseId: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onDecided(
    ReplenishmentSuggestionsDecided event,
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    emit(
      state.copyWith(
        decidingSuggestionId: event.suggestionId,
        clearDecisionFailure: true,
      ),
    );

    final result = await decideSuggestion(
      organizationId: state.organizationId,
      suggestionId: event.suggestionId,
      userId: state.userId,
      action: event.action,
      adjustedQuantity: event.adjustedQuantity,
      note: event.note,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<ReplenishmentDecisionResult>():
        // A decided suggestion's `decisionAudit`/`decidedByName`/`decidedAt`
        // only really exist server-side — reloading the first page (instead
        // of patching the list entity locally) is the simplest way to show
        // exactly what the Cloud Function persisted, same tradeoff already
        // accepted by resetting pagination after a mutation elsewhere in
        // this codebase (e.g. `CartShareCubit.review`'s own full reload).
        emit(state.copyWith(clearDecidingSuggestionId: true));
        await _loadFirstPage(emit);
      case AppFailure<ReplenishmentDecisionResult>(failure: final failure):
        emit(
          state.copyWith(
            clearDecidingSuggestionId: true,
            decisionFailure: failure,
          ),
        );
    }
  }

  Future<void> _loadFirstPage(
    Emitter<ReplenishmentSuggestionsState> emit,
  ) async {
    final requestToken = ++_requestToken;
    final result = await listSuggestions(
      organizationId: state.organizationId,
      requestedByUserId: state.userId,
      limit: kReplenishmentSuggestionsPageSize,
      status: state.status,
      warehouseId: state.warehouseId,
    );
    if (emit.isDone || requestToken != _requestToken) return;

    switch (result) {
      case AppSuccess<ReplenishmentSuggestionPage>(value: final page):
        emit(
          state.copyWith(
            loadStatus: ReplenishmentSuggestionsLoadStatus.ready,
            suggestions: page.suggestions,
            hasMore: page.hasMore,
            isLoadingMore: false,
            nextCursor: page.nextCursor,
            clearNextCursor: page.nextCursor == null,
            clearFailure: true,
          ),
        );
      case AppFailure<ReplenishmentSuggestionPage>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: ReplenishmentSuggestionsLoadStatus.failure,
            suggestions: const <ReplenishmentSuggestion>[],
            hasMore: false,
            isLoadingMore: false,
            clearNextCursor: true,
            failure: failure,
          ),
        );
    }
  }
}
