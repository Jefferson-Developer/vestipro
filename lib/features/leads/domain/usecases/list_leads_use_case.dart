import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/lead_list_filters.dart';
import '../entities/lead_page_result.dart';
import '../repositories/lead_repository.dart';

/// Lists Leads for the CRM entry-point screen (TASK-056): combinable
/// origin/status/responsible filters, free-text search over name/document
/// and cursor-based pagination.
@injectable
final class ListLeadsUseCase {
  const ListLeadsUseCase(this._repository);

  final LeadRepository _repository;

  Future<AppResult<LeadPageResult>> call({
    required String organizationId,
    String? companyId,
    LeadListFilters filters = LeadListFilters.empty,
    String searchQuery = '',
    String? cursor,
    int limit = 20,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final fieldErrors = <String, String>{};

    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (limit <= 0 || limit > 100) {
      fieldErrors['limit'] = 'Limit must be between 1 and 100.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<LeadPageResult>(
        ValidationFailure(
          'Invalid lead listing payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_lead_list_payload',
        ),
      );
    }

    final trimmedCompanyId = companyId?.trim();
    return _repository.listPage(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId == null || trimmedCompanyId.isEmpty
          ? null
          : trimmedCompanyId,
      filters: filters.normalized(),
      searchQuery: searchQuery.trim(),
      cursor: cursor?.trim().isEmpty ?? true ? null : cursor!.trim(),
      limit: limit,
    );
  }
}
