import '../../../../core/errors/errors.dart';
import '../../domain/entities/representative_dashboard_filters.dart';
import '../../domain/entities/representative_dashboard_snapshot.dart';

enum RepresentativeDashboardStatus { initial, loading, forbidden, error, ready }

final class RepresentativeDashboardState {
  const RepresentativeDashboardState({
    this.status = RepresentativeDashboardStatus.initial,
    this.organizationId = '',
    this.requesterUserId = '',
    this.filters = const RepresentativeDashboardFilters(
      companyId: '',
      sellerId: '',
      year: 2024,
      month: 1,
    ),
    this.snapshot,
    this.failure,
  });

  final RepresentativeDashboardStatus status;
  final String organizationId;
  final String requesterUserId;
  final RepresentativeDashboardFilters filters;
  final RepresentativeDashboardSnapshot? snapshot;
  final Failure? failure;

  RepresentativeDashboardState copyWith({
    RepresentativeDashboardStatus? status,
    String? organizationId,
    String? requesterUserId,
    RepresentativeDashboardFilters? filters,
    RepresentativeDashboardSnapshot? snapshot,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return RepresentativeDashboardState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      requesterUserId: requesterUserId ?? this.requesterUserId,
      filters: filters ?? this.filters,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
