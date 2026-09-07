import '../../../../core/errors/errors.dart';
import '../../domain/entities/replenishment_suggestion.dart';
import '../../domain/value_objects/replenishment_suggestion_status.dart';

enum ReplenishmentSuggestionsLoadStatus {
  initial,
  loading,
  ready,
  loadingMore,
  failure,
}

const int kReplenishmentSuggestionsPageSize = 25;

final class ReplenishmentSuggestionsState {
  const ReplenishmentSuggestionsState({
    this.loadStatus = ReplenishmentSuggestionsLoadStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.suggestions = const <ReplenishmentSuggestion>[],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.nextCursor,
    this.failure,
    this.status,
    this.warehouseId = '',
    this.decidingSuggestionId,
    this.decisionFailure,
  });

  final ReplenishmentSuggestionsLoadStatus loadStatus;
  final String organizationId;
  final String userId;
  final List<ReplenishmentSuggestion> suggestions;
  final bool hasMore;
  final bool isLoadingMore;
  final DateTime? nextCursor;
  final Failure? failure;
  final ReplenishmentSuggestionStatus? status;
  final String warehouseId;

  /// The id of the suggestion currently being decided (accept/adjust/
  /// discard in flight) — drives a per-row loading indicator so a gestor
  /// cannot double-submit a decision by tapping twice.
  final String? decidingSuggestionId;

  /// Set only when the most recent decision attempt failed — never removes
  /// the suggestion from the list, so the gestor can retry.
  final Failure? decisionFailure;

  bool get isInitialLoading =>
      loadStatus == ReplenishmentSuggestionsLoadStatus.initial ||
      loadStatus == ReplenishmentSuggestionsLoadStatus.loading;

  bool get hasActiveFilters => status != null || warehouseId.trim().isNotEmpty;

  ReplenishmentSuggestionsState copyWith({
    ReplenishmentSuggestionsLoadStatus? loadStatus,
    String? organizationId,
    String? userId,
    List<ReplenishmentSuggestion>? suggestions,
    bool? hasMore,
    bool? isLoadingMore,
    DateTime? nextCursor,
    bool clearNextCursor = false,
    Failure? failure,
    bool clearFailure = false,
    ReplenishmentSuggestionStatus? status,
    bool clearStatus = false,
    String? warehouseId,
    bool clearWarehouseId = false,
    String? decidingSuggestionId,
    bool clearDecidingSuggestionId = false,
    Failure? decisionFailure,
    bool clearDecisionFailure = false,
  }) {
    return ReplenishmentSuggestionsState(
      loadStatus: loadStatus ?? this.loadStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      suggestions: suggestions ?? this.suggestions,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      failure: clearFailure ? null : failure ?? this.failure,
      status: clearStatus ? null : status ?? this.status,
      warehouseId: clearWarehouseId ? '' : warehouseId ?? this.warehouseId,
      decidingSuggestionId: clearDecidingSuggestionId
          ? null
          : decidingSuggestionId ?? this.decidingSuggestionId,
      decisionFailure: clearDecisionFailure
          ? null
          : decisionFailure ?? this.decisionFailure,
    );
  }
}
