import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/branch_address.dart';
import '../value_objects/branch_status.dart';
import '../value_objects/branch_type.dart';

part 'branch.freezed.dart';

/// A store/showroom/unit configured under a [Company] (`tasks.md`, seção
/// 3.1/3.2 — "Loja Blumenau", "Loja Jaraguá", "Showroom São Paulo"). A single
/// Company supports N Branches.
///
/// [organizationId] and [companyId] are assigned once, at creation, and are
/// never changed afterwards: [BranchRepository] only exposes
/// [BranchRepository.create], [BranchRepository.getById],
/// [BranchRepository.listByCompany] and [BranchRepository.update] — the
/// latter never accepts nor rewrites [organizationId]/[companyId], only
/// mutable fields and audit metadata.
@freezed
abstract class Branch with _$Branch {
  const factory Branch({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required BranchStatus status,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Branch;
}
