import '../../../../core/utils/utils.dart';
import '../entities/lead.dart';
import '../entities/lead_list_filters.dart';
import '../entities/lead_page_result.dart';

/// Domain contract for Lead persistence, decoupled from Firestore/Drift.
///
/// TASK-055 modeled the entity and the qualification/conversion use cases
/// with only [create]/[update]/[getById] as a contract-only repository, no
/// concrete implementation. TASK-056 adds [listPage] (combinable
/// origin/status/responsible filters, free-text search and cursor
/// pagination, mirroring `CustomerRepository.listPortfolioPage` from
/// TASK-048) and a first concrete implementation
/// (`SharedPreferencesLeadRepository`), matching the precedent set by
/// `SharedPreferencesCustomerRepository`: a durable local store used until a
/// Firestore/outbox-backed implementation exists.
abstract interface class LeadRepository {
  Future<AppResult<Lead>> create({required Lead lead});

  Future<AppResult<Lead>> update({required Lead lead});

  Future<AppResult<Lead>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<LeadPageResult>> listPage({
    required String organizationId,
    String? companyId,
    required LeadListFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
  });
}
