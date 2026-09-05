import '../../../../core/errors/errors.dart';
import '../../domain/entities/targets_dashboard_filters.dart';
import '../../domain/entities/targets_dashboard_snapshot.dart';

enum TargetsDashboardStatus { initial, loading, ready, forbidden, error }

final class TargetsDashboardState {
  const TargetsDashboardState({
    this.status = TargetsDashboardStatus.initial,
    this.organizationId = '',
    this.userId = '',
    this.filters = const TargetsDashboardFilters(
      companyId: '',
      year: 2024,
      month: 1,
    ),
    this.snapshot,
    this.drillPath = const <String>[],
    this.failure,
  });

  final TargetsDashboardStatus status;
  final String organizationId;
  final String userId;
  final TargetsDashboardFilters filters;
  final TargetsDashboardSnapshot? snapshot;
  final List<String> drillPath;
  final Failure? failure;

  TargetsDashboardRow? get drilledRow {
    var row = snapshot?.root;
    for (final id in drillPath) {
      row = row?.children.where((child) => child.id == id).firstOrNull;
    }
    return row;
  }

  TargetsDashboardState copyWith({
    TargetsDashboardStatus? status,
    String? organizationId,
    String? userId,
    TargetsDashboardFilters? filters,
    TargetsDashboardSnapshot? snapshot,
    List<String>? drillPath,
    Failure? failure,
    bool clearFailure = false,
  }) => TargetsDashboardState(
    status: status ?? this.status,
    organizationId: organizationId ?? this.organizationId,
    userId: userId ?? this.userId,
    filters: filters ?? this.filters,
    snapshot: snapshot ?? this.snapshot,
    drillPath: drillPath ?? this.drillPath,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
