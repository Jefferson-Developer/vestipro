import '../value_objects/lead_status.dart';

/// Combinable filters for [ListLeadsUseCase] (TASK-056): origin, status and
/// responsible rep, mirroring `CustomerPortfolioFilters` (TASK-048).
final class LeadListFilters {
  const LeadListFilters({
    this.statuses = const <LeadStatus>{},
    this.sourceCodes = const <String>{},
    this.responsibleUserIds = const <String>{},
  });

  final Set<LeadStatus> statuses;
  final Set<String> sourceCodes;
  final Set<String> responsibleUserIds;

  static const empty = LeadListFilters();

  bool get isEmpty =>
      statuses.isEmpty && sourceCodes.isEmpty && responsibleUserIds.isEmpty;

  LeadListFilters normalized() {
    return LeadListFilters(
      statuses: Set<LeadStatus>.unmodifiable(statuses),
      sourceCodes: Set<String>.unmodifiable(
        sourceCodes.map((code) => code.trim()).where((code) => code.isNotEmpty),
      ),
      responsibleUserIds: Set<String>.unmodifiable(
        responsibleUserIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      ),
    );
  }

  LeadListFilters copyWith({
    Set<LeadStatus>? statuses,
    Set<String>? sourceCodes,
    Set<String>? responsibleUserIds,
  }) {
    return LeadListFilters(
      statuses: statuses ?? this.statuses,
      sourceCodes: sourceCodes ?? this.sourceCodes,
      responsibleUserIds: responsibleUserIds ?? this.responsibleUserIds,
    ).normalized();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeadListFilters &&
        _setEquals(other.statuses, statuses) &&
        _setEquals(other.sourceCodes, sourceCodes) &&
        _setEquals(other.responsibleUserIds, responsibleUserIds);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(statuses.map((status) => status.index).toList()..sort()),
    Object.hashAll(sourceCodes.toList()..sort()),
    Object.hashAll(responsibleUserIds.toList()..sort()),
  );

  bool _setEquals<T>(Set<T> first, Set<T> second) {
    return first.length == second.length && first.containsAll(second);
  }
}
