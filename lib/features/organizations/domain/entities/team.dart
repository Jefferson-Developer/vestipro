import 'package:freezed_annotation/freezed_annotation.dart';

part 'team.freezed.dart';

/// A group of users scoped to one [Organization] (`tasks.md`, seção 3.3),
/// used to organize sales reps/managers for carteira, metas e RBAC de
/// escopo (ex.: um `SALES_MANAGER` só vendo os pedidos do próprio Team).
///
/// [organizationId] is assigned once, at creation, and is never changed
/// afterwards: [TeamRepository] only exposes [TeamRepository.create],
/// [TeamRepository.getById], [TeamRepository.listByOrganization] and
/// [TeamRepository.addMember] — none of them can rewrite [organizationId].
@freezed
abstract class Team with _$Team {
  const factory Team({
    required String id,
    required String organizationId,
    required String name,
    String? companyId,
    String? branchId,
    @Default('') String managerUserId,
    @Default(<String>[]) List<String> memberIds,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Team;
}
