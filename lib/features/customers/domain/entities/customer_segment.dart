import 'customer_segment_criteria.dart';
import '../value_objects/customer_segment_visibility.dart';

/// A saved, reusable combination of carteira filters (TASK-053).
///
/// Always scoped by [organizationId] — never reusable across organizations,
/// mirroring the tenant isolation already enforced for [Customer] itself.
/// [visibility] controls who else can see it: [CustomerSegmentVisibility]
/// documents the two modes.
final class CustomerSegment {
  const CustomerSegment({
    required this.id,
    required this.organizationId,
    required this.name,
    required this.criteria,
    required this.visibility,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.updatedBy,
    this.version = 1,
  });

  final String id;
  final String organizationId;
  final String name;
  final CustomerSegmentCriteria criteria;
  final CustomerSegmentVisibility visibility;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String updatedBy;
  final int version;

  bool get isPrivate => visibility == CustomerSegmentVisibility.private;

  bool get isShared => visibility == CustomerSegmentVisibility.shared;

  /// Whether [userId] can see this segment in the segment list/quick
  /// filters: the creator always can; everyone else only when it is shared.
  /// Whether [userId] can see the carteira/segments feature at all is a
  /// separate RBAC decision (`Capability.customerView`) enforced by the
  /// page, not by this method.
  bool isVisibleTo(String userId) => isShared || createdBy == userId;

  /// Whether [userId] may edit or delete this segment. Only the creator can
  /// change a segment's criteria, name or visibility in this version —
  /// sharing only affects who can *apply* it, not who can manage it.
  bool isEditableBy(String userId) => createdBy == userId;

  CustomerSegment copyWith({
    String? name,
    CustomerSegmentCriteria? criteria,
    CustomerSegmentVisibility? visibility,
    DateTime? updatedAt,
    String? updatedBy,
    int? version,
  }) {
    return CustomerSegment(
      id: id,
      organizationId: organizationId,
      name: name ?? this.name,
      criteria: criteria ?? this.criteria,
      visibility: visibility ?? this.visibility,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      version: version ?? this.version,
    );
  }
}
