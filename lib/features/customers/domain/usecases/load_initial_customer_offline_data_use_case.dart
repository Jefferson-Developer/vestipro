import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../users/users.dart';
import '../entities/customer.dart';
import '../entities/customer_offline_load_summary.dart';
import '../entities/customer_portfolio_filters.dart';
import '../entities/customer_portfolio_page_result.dart';
import '../repositories/customer_local_store_repository.dart';
import '../repositories/customer_repository.dart';

/// Prepares the on-device Customer cache (TASK-054) that the offline
/// portfolio (TASK-051) and 360º detail (TASK-052) read when the app has no
/// connectivity.
///
/// This performs a full initial load, not incremental sync: it resolves
/// which customers the signed-in user may see — `SALES_REP` gets only their
/// own portfolio, `SALES_MANAGER` gets their team(s)' portfolio, `ADMIN`/
/// `OWNER` get the whole organization scope — then downloads that set page
/// by page, capped at [maxCustomers] so a very large organization cannot
/// exhaust device storage/memory, and replaces the local store with exactly
/// that set. The incremental sync engine (TASK-109) is expected to take over
/// keeping the local store fresh after this initial load.
@injectable
class LoadInitialCustomerOfflineDataUseCase {
  const LoadInitialCustomerOfflineDataUseCase(
    this._customerRepository,
    this._visibilityService,
    this._assignmentRepository,
    this._localStoreRepository,
  );

  final CustomerRepository _customerRepository;
  final PortfolioVisibilityService _visibilityService;
  final PortfolioAssignmentRepository _assignmentRepository;
  final CustomerLocalStoreRepository _localStoreRepository;

  static const _minPageSize = 1;
  static const _maxPageSize = 100;
  static const _defaultPageSize = 100;
  static const _defaultMaxCustomers = 2000;

  Future<AppResult<CustomerOfflineLoadSummary>> call({
    required String organizationId,
    required String companyId,
    required String userId,
    int pageSize = _defaultPageSize,
    int maxCustomers = _defaultMaxCustomers,
    DateTime? now,
  }) async {
    final normalizedOrganizationId = organizationId.trim();
    final normalizedCompanyId = companyId.trim();
    final normalizedUserId = userId.trim();
    final fieldErrors = <String, String>{};

    if (normalizedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (normalizedCompanyId.isEmpty) {
      fieldErrors['companyId'] = 'CompanyId is required.';
    }
    if (normalizedUserId.isEmpty) {
      fieldErrors['userId'] = 'UserId is required.';
    }
    if (pageSize < _minPageSize || pageSize > _maxPageSize) {
      fieldErrors['pageSize'] =
          'PageSize must be between $_minPageSize and $_maxPageSize.';
    }
    if (maxCustomers < 1) {
      fieldErrors['maxCustomers'] = 'MaxCustomers must be at least 1.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<CustomerOfflineLoadSummary>(
        ValidationFailure(
          'Invalid customer offline load payload.',
          code: 'invalid_customer_offline_load_payload',
          fieldErrors: fieldErrors,
        ),
      );
    }

    final resolvedNow = now ?? DateTime.now().toUtc();

    final visibilityResult = await _visibilityService.resolve(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
      userId: normalizedUserId,
    );
    if (visibilityResult case AppFailure<CustomerVisibilityFilter>(
      failure: final failure,
    )) {
      return AppFailure<CustomerOfflineLoadSummary>(failure);
    }
    final visibility =
        (visibilityResult as AppSuccess<CustomerVisibilityFilter>).value;

    if (!visibility.canReadAny) {
      // No visible portfolio (e.g. inactive membership or unsupported role):
      // never leave stale customers from a previous, broader role on the
      // device.
      return _clearAndSucceed(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        loadedAt: resolvedNow,
      );
    }

    final assignmentsResult = await _loadAssignments(visibility);
    if (assignmentsResult case AppFailure<List<PortfolioAssignment>>(
      failure: final failure,
    )) {
      return AppFailure<CustomerOfflineLoadSummary>(failure);
    }
    final assignments =
        (assignmentsResult as AppSuccess<List<PortfolioAssignment>>).value;
    if (visibility.mode == CustomerVisibilityMode.ownCustomers &&
        assignments.isEmpty) {
      return _clearAndSucceed(
        organizationId: normalizedOrganizationId,
        companyId: normalizedCompanyId,
        loadedAt: resolvedNow,
      );
    }

    final collected = <Customer>[];
    String? cursor;
    var truncated = false;

    while (true) {
      final pageResult = await _customerRepository.listPortfolioPage(
        visibility: visibility,
        activeAssignments: assignments,
        filters: CustomerPortfolioFilters.empty,
        searchQuery: '',
        cursor: cursor,
        limit: pageSize,
        now: resolvedNow,
      );
      if (pageResult case AppFailure<CustomerPortfolioPageResult>(
        failure: final failure,
      )) {
        return AppFailure<CustomerOfflineLoadSummary>(failure);
      }
      final page =
          (pageResult as AppSuccess<CustomerPortfolioPageResult>).value;
      collected.addAll(page.customers);

      if (collected.length >= maxCustomers) {
        truncated = page.hasMore || collected.length > maxCustomers;
        break;
      }
      if (!page.hasMore) {
        break;
      }
      cursor = page.nextCursor;
    }

    final boundedCustomers = collected.length > maxCustomers
        ? collected.sublist(0, maxCustomers)
        : collected;

    final replaceResult = await _localStoreRepository.replaceInitialLoad(
      organizationId: normalizedOrganizationId,
      companyId: normalizedCompanyId,
      customers: boundedCustomers,
    );
    if (replaceResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<CustomerOfflineLoadSummary>(failure);
    }

    return AppSuccess<CustomerOfflineLoadSummary>(
      CustomerOfflineLoadSummary(
        downloadedCount: boundedCustomers.length,
        truncated: truncated,
        loadedAt: resolvedNow,
      ),
    );
  }

  Future<AppResult<CustomerOfflineLoadSummary>> _clearAndSucceed({
    required String organizationId,
    required String companyId,
    required DateTime loadedAt,
  }) async {
    final replaceResult = await _localStoreRepository.replaceInitialLoad(
      organizationId: organizationId,
      companyId: companyId,
      customers: const <Customer>[],
    );
    if (replaceResult case AppFailure<void>(failure: final failure)) {
      return AppFailure<CustomerOfflineLoadSummary>(failure);
    }
    return AppSuccess<CustomerOfflineLoadSummary>(
      CustomerOfflineLoadSummary(
        downloadedCount: 0,
        truncated: false,
        loadedAt: loadedAt,
      ),
    );
  }

  /// Mirrors `ListCustomerPortfolioUseCase._loadAssignments`: which active
  /// `PortfolioAssignment`s matter depends on the resolved visibility mode.
  /// Kept local to this use case (rather than extracted into a shared
  /// component) to keep TASK-054's change footprint limited to the offline
  /// load path; consolidating both call sites is a reasonable follow-up, not
  /// required for this task's scope.
  Future<AppResult<List<PortfolioAssignment>>> _loadAssignments(
    CustomerVisibilityFilter visibility,
  ) {
    return switch (visibility.mode) {
      CustomerVisibilityMode.allOrganization =>
        Future<AppResult<List<PortfolioAssignment>>>.value(
          const AppSuccess<List<PortfolioAssignment>>(<PortfolioAssignment>[]),
        ),
      CustomerVisibilityMode.teams =>
        _assignmentRepository
            .listActiveByOrganization(
              organizationId: visibility.organizationId,
              companyId: visibility.companyId,
            )
            .then(
              (result) => result.fold(
                onSuccess: (assignments) =>
                    AppSuccess<List<PortfolioAssignment>>(
                      assignments
                          .where(
                            (assignment) =>
                                visibility.teamIds.contains(assignment.teamId),
                          )
                          .toList(growable: false),
                    ),
                onFailure: AppFailure<List<PortfolioAssignment>>.new,
              ),
            ),
      CustomerVisibilityMode.ownCustomers =>
        _assignmentRepository.listActiveByUser(
          organizationId: visibility.organizationId,
          companyId: visibility.companyId,
          userId: visibility.userId,
        ),
      CustomerVisibilityMode.none =>
        Future<AppResult<List<PortfolioAssignment>>>.value(
          const AppSuccess<List<PortfolioAssignment>>(<PortfolioAssignment>[]),
        ),
    };
  }
}
