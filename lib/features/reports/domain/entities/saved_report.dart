import 'report_definition.dart';

/// Who else, besides [SavedReport.ownerId], can see a saved report
/// (TASK-145): [private] (only the owner), [team] (the owner's own team(s),
/// always re-derived from their *current* real Membership, never a snapshot
/// the client could forge) or [organization] (every active member).
enum SavedReportVisibility { private, team, organization }

extension SavedReportVisibilityCode on SavedReportVisibility {
  String get code => name;

  static SavedReportVisibility fromCode(String code) =>
      SavedReportVisibility.values.byName(code);
}

/// A [ReportDefinition] (TASK-144) saved by a user for quick re-execution,
/// optionally shared with their team or the whole organization (TASK-145).
///
/// Only the [ReportDefinition] and sharing metadata are persisted — never a
/// cached [ReportQueryResult]: re-running a [SavedReport] always calls
/// `ExecuteReportQuery` again, scoped to whoever is executing it (which may
/// legitimately return different rows than what [ownerId] would see for the
/// exact same [definition]).
final class SavedReport {
  const SavedReport({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.ownerId,
    required this.name,
    required this.definition,
    required this.visibility,
    this.sharedWithTeamIds = const <String>[],
    required this.favorite,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.version = 1,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final String ownerId;
  final String name;
  final ReportDefinition definition;
  final SavedReportVisibility visibility;

  /// Snapshot of [ownerId]'s own `Membership.teamIds` at the moment
  /// [visibility] was last set to [SavedReportVisibility.team] —
  /// denormalized so a client `listSharedWithMe` query can filter by
  /// `array-contains-any` without a server-side join. The real
  /// authorization decision (`firestore.rules`) never trusts this
  /// (potentially stale) copy: it always re-derives the owner's *current*
  /// teams from their live Membership before granting read access, the same
  /// "always re-read, never trust a denormalized snapshot" rule
  /// `canReadOrder`/`managerCanReadOrder` already use. Always empty for
  /// [SavedReportVisibility.private]/[SavedReportVisibility.organization].
  final List<String> sharedWithTeamIds;
  final bool favorite;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  bool get isShared => visibility != SavedReportVisibility.private;

  bool isOwnedBy(String userId) => ownerId == userId;

  SavedReport copyWith({
    String? name,
    ReportDefinition? definition,
    SavedReportVisibility? visibility,
    List<String>? sharedWithTeamIds,
    bool? favorite,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
  }) => SavedReport(
    id: id,
    organizationId: organizationId,
    companyId: companyId,
    ownerId: ownerId,
    name: name ?? this.name,
    definition: definition ?? this.definition,
    visibility: visibility ?? this.visibility,
    sharedWithTeamIds: sharedWithTeamIds ?? this.sharedWithTeamIds,
    favorite: favorite ?? this.favorite,
    createdAt: createdAt,
    createdBy: createdBy,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    version: version ?? this.version,
  );
}
