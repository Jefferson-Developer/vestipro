import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/company_status.dart';

part 'company.freezed.dart';

/// A company/brand configured under an [Organization] (`tasks.md`, seção
/// 3.1/3.2 — Organização "Grupo Fashion XPTO" com empresas "Marca A"/"Marca
/// B"). A single Organization supports N Companies.
///
/// [organizationId] is assigned once, at creation, and is never changed
/// afterwards: [CompanyRepository] only exposes
/// [CompanyRepository.create], [CompanyRepository.getById],
/// [CompanyRepository.listByOrganization] and [CompanyRepository.update] —
/// the latter never accepts nor rewrites [organizationId], only mutable
/// fields and audit metadata.
@freezed
abstract class Company with _$Company {
  const factory Company({
    required String id,
    required String organizationId,
    required String name,
    String? legalName,
    String? taxId,
    required CompanyStatus status,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Company;
}
