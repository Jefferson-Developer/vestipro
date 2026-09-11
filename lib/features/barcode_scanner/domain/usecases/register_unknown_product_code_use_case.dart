import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/utils/utils.dart';
import '../../../audit_log/domain/audit_log_entry_factory.dart';
import '../../../audit_log/domain/entities/audit_log_entry.dart';
import '../../../audit_log/domain/repositories/audit_log_repository.dart';
import '../../../audit_log/domain/value_objects/audit_action.dart';
import '../entities/alternate_product_code.dart';
import '../repositories/product_code_lookup_repository.dart';

/// Registers an alternate code for a product/variant (TASK-216, "código
/// desconhecido pode gerar sugestão de cadastro/correção apenas para perfil
/// autorizado") — [Capability.catalogManage] is re-checked here as
/// defense-in-depth, the same precedent `DecideReplenishmentSuggestionUseCase`
/// already sets: the client-side check only improves UX, Firestore Security
/// Rules independently re-validate the same Membership/role before the write
/// is ever persisted.
///
/// Registering a code never resolves/authorizes anything by itself — it only
/// grows the set of codes `ProductCodeLookupRepository.resolveCode` matches
/// against, exactly like any other catalog edit.
@injectable
final class RegisterUnknownProductCodeUseCase {
  const RegisterUnknownProductCodeUseCase(
    this._repository,
    this._permissionService,
    this._auditLogRepository,
    this._analyticsService,
  );

  final ProductCodeLookupRepository _repository;
  final PermissionService _permissionService;
  final AuditLogRepository _auditLogRepository;
  final AnalyticsService _analyticsService;

  Future<AppResult<AlternateProductCode>> call({
    required String organizationId,
    required String code,
    required String productId,
    String? variantId,
    required String registeredBy,
    required String actorName,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCode = code.trim();
    final trimmedProductId = productId.trim();
    final trimmedVariantId = variantId?.trim();
    final trimmedRegisteredBy = registeredBy.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedCode.isEmpty) fieldErrors['code'] = 'Code is required.';
    if (trimmedProductId.isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    if (trimmedRegisteredBy.isEmpty) {
      fieldErrors['registeredBy'] = 'RegisteredBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<AlternateProductCode>(
        ValidationFailure(
          'Invalid alternate product code registration payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_alternate_product_code_payload',
        ),
      );
    }

    final permissionResult = await _permissionService.hasPermission(
      organizationId: trimmedOrganizationId,
      userId: trimmedRegisteredBy,
      capability: Capability.catalogManage,
    );
    if (permissionResult is AppFailure<bool>) {
      return AppFailure<AlternateProductCode>(permissionResult.failure);
    }
    if (!(permissionResult as AppSuccess<bool>).value) {
      return const AppFailure<AlternateProductCode>(
        PermissionFailure(
          'User is not allowed to register a catalog code correction.',
          code: 'alternate_product_code_register_denied',
        ),
      );
    }

    final result = await _repository.registerAlternateCode(
      organizationId: trimmedOrganizationId,
      code: trimmedCode,
      productId: trimmedProductId,
      variantId: trimmedVariantId == null || trimmedVariantId.isEmpty
          ? null
          : trimmedVariantId,
      registeredBy: trimmedRegisteredBy,
    );
    if (result case AppSuccess<AlternateProductCode>(value: final registered)) {
      final auditEntry = AuditLogEntryFactory.build(
        organizationId: trimmedOrganizationId,
        actorUserId: trimmedRegisteredBy,
        actorName: actorName.trim().isEmpty
            ? trimmedRegisteredBy
            : actorName.trim(),
        action: AuditAction.productAlternateCodeRegistered,
        entityType: 'product',
        entityId: trimmedProductId,
        newValue: <String, Object?>{
          'code': registered.code,
          if (registered.variantId != null) 'variantId': registered.variantId,
        },
      );
      final auditResult = await _auditLogRepository.record(auditEntry);
      if (auditResult is AppFailure<AuditLogEntry>) {
        return AppFailure<AlternateProductCode>(auditResult.failure);
      }
      await _analyticsService.logEvent(
        AnalyticsEvents.barcodeAlternateCodeRegistered,
        parameters: <String, Object?>{
          'organization_id': trimmedOrganizationId,
          'product_id': trimmedProductId,
          'has_variant': registered.variantId != null,
        },
      );
    }
    return result;
  }
}
