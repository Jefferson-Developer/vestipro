import '../../../../core/errors/errors.dart';
import '../../../users/users.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_list_filters.dart';

enum LeadListLoadStatus { initial, loading, ready, loadingMore, failure }

enum LeadListActionStatus { idle, inProgress, failure }

final class LeadListState {
  const LeadListState({
    this.status = LeadListLoadStatus.initial,
    this.organizationId = '',
    this.companyId,
    this.userId = '',
    this.searchQuery = '',
    this.filters = LeadListFilters.empty,
    this.leads = const <Lead>[],
    this.hasMore = false,
    this.nextCursor,
    this.isFromLocalCache = false,
    this.responsibleUsers = const <OrganizationUser>[],
    this.failure,
    this.actionStatus = LeadListActionStatus.idle,
    this.pendingActionLeadId,
    this.actionFailure,
  });

  final LeadListLoadStatus status;
  final String organizationId;
  final String? companyId;
  final String userId;
  final String searchQuery;
  final LeadListFilters filters;
  final List<Lead> leads;
  final bool hasMore;
  final String? nextCursor;
  final bool isFromLocalCache;
  final List<OrganizationUser> responsibleUsers;
  final Failure? failure;
  final LeadListActionStatus actionStatus;
  final String? pendingActionLeadId;
  final Failure? actionFailure;

  bool get isInitialLoading =>
      status == LeadListLoadStatus.initial ||
      status == LeadListLoadStatus.loading;

  bool get isLoadingMore => status == LeadListLoadStatus.loadingMore;

  bool isActionPending(String leadId) =>
      actionStatus == LeadListActionStatus.inProgress &&
      pendingActionLeadId == leadId;

  LeadListState copyWith({
    LeadListLoadStatus? status,
    String? organizationId,
    String? companyId,
    bool clearCompanyId = false,
    String? userId,
    String? searchQuery,
    LeadListFilters? filters,
    List<Lead>? leads,
    bool? hasMore,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isFromLocalCache,
    List<OrganizationUser>? responsibleUsers,
    Failure? failure,
    bool clearFailure = false,
    LeadListActionStatus? actionStatus,
    String? pendingActionLeadId,
    bool clearPendingActionLeadId = false,
    Failure? actionFailure,
    bool clearActionFailure = false,
  }) {
    return LeadListState(
      status: status ?? this.status,
      organizationId: organizationId ?? this.organizationId,
      companyId: clearCompanyId ? null : companyId ?? this.companyId,
      userId: userId ?? this.userId,
      searchQuery: searchQuery ?? this.searchQuery,
      filters: filters ?? this.filters,
      leads: leads ?? this.leads,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isFromLocalCache: isFromLocalCache ?? this.isFromLocalCache,
      responsibleUsers: responsibleUsers ?? this.responsibleUsers,
      failure: clearFailure ? null : failure ?? this.failure,
      actionStatus: actionStatus ?? this.actionStatus,
      pendingActionLeadId: clearPendingActionLeadId
          ? null
          : pendingActionLeadId ?? this.pendingActionLeadId,
      actionFailure: clearActionFailure
          ? null
          : actionFailure ?? this.actionFailure,
    );
  }
}
