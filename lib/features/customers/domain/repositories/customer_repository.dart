import '../../../../core/utils/utils.dart';
import '../entities/customer.dart';
import '../value_objects/cnpj_cpf.dart';
import '../value_objects/customer_sensitive_field.dart';

/// Domain contract for Customer persistence.
///
/// Implementations may use Firestore, Drift or an outbox-backed composition,
/// but callers only see tenant-scoped methods. Document uniqueness is scoped
/// by organization, not by company, as required by TASK-048.
abstract interface class CustomerRepository {
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  });

  Future<AppResult<Customer>> create({required Customer customer});

  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  });

  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  });

  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  });
}
