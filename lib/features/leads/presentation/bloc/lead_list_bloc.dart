import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/organizations.dart';
import '../../../users/users.dart';
import '../../domain/entities/lead.dart';
import '../../domain/entities/lead_page_result.dart';
import '../../domain/usecases/disqualify_lead_use_case.dart';
import '../../domain/usecases/list_leads_use_case.dart';
import '../../domain/usecases/qualify_lead_use_case.dart';
import 'lead_list_event.dart';
import 'lead_list_state.dart';

/// Drives `LeadListPage` (TASK-056): combinable origin/status/responsible
/// filters, debounced search, cursor pagination and the qualify/disqualify
/// contextual actions, mirroring `CustomerPortfolioBloc` (TASK-048/053).
///
/// Qualify/disqualify replace the affected [Lead] in [LeadListState.leads]
/// in place on success, so the list reflects the new status immediately
/// without requiring the caller to trigger a manual refresh (per TASK-056's
/// "regras de negocio e restricoes").
@injectable
final class LeadListBloc extends Bloc<LeadListEvent, LeadListState> {
  LeadListBloc({
    required this.listLeads,
    required this.qualifyLead,
    required this.disqualifyLead,
    required this.listOrganizationUsers,
  }) : super(const LeadListState()) {
    on<LeadListStarted>(_onStarted);
    on<LeadListSearchChanged>(_onSearchChanged);
    on<LeadListSearchDebounced>(_onSearchDebounced);
    on<LeadListFiltersChanged>(_onFiltersChanged);
    on<LeadListNextPageRequested>(_onNextPageRequested);
    on<LeadListRetried>(_onRetried);
    on<LeadListLeadQualified>(_onLeadQualified);
    on<LeadListLeadDisqualified>(_onLeadDisqualified);
    on<LeadListActionDismissed>(_onActionDismissed);
  }

  static const pageSize = 20;
  static const searchDebounce = Duration(milliseconds: 300);

  final ListLeadsUseCase listLeads;
  final QualifyLeadUseCase qualifyLead;
  final DisqualifyLeadUseCase disqualifyLead;
  final ListOrganizationUsersUseCase listOrganizationUsers;
  Timer? _searchTimer;
  int _searchToken = 0;
  int _requestToken = 0;

  Future<void> _onStarted(
    LeadListStarted event,
    Emitter<LeadListState> emit,
  ) async {
    emit(
      const LeadListState().copyWith(
        status: LeadListLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        searchQuery: event.searchQuery,
        filters: event.filters.normalized(),
        leads: const <Lead>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );

    final usersResult = await listOrganizationUsers(event.organizationId);
    if (emit.isDone) return;
    final responsibleUsers = usersResult.fold(
      onSuccess: (users) => users
          .where((user) => user.status == MembershipStatus.active)
          .toList(growable: false),
      onFailure: (_) => const <OrganizationUser>[],
    );
    emit(state.copyWith(responsibleUsers: responsibleUsers));

    await _loadFirstPage(emit);
  }

  void _onSearchChanged(
    LeadListSearchChanged event,
    Emitter<LeadListState> emit,
  ) {
    final token = ++_searchToken;
    _requestToken += 1;
    _searchTimer?.cancel();
    emit(state.copyWith(searchQuery: event.searchQuery, clearFailure: true));
    _searchTimer = Timer(searchDebounce, () {
      if (!isClosed) add(LeadListSearchDebounced(token));
    });
  }

  Future<void> _onSearchDebounced(
    LeadListSearchDebounced event,
    Emitter<LeadListState> emit,
  ) async {
    if (event.token != _searchToken) return;
    emit(
      state.copyWith(
        status: LeadListLoadStatus.loading,
        leads: const <Lead>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onFiltersChanged(
    LeadListFiltersChanged event,
    Emitter<LeadListState> emit,
  ) async {
    _searchTimer?.cancel();
    _searchToken += 1;
    emit(
      state.copyWith(
        status: LeadListLoadStatus.loading,
        filters: event.filters.normalized(),
        leads: const <Lead>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onNextPageRequested(
    LeadListNextPageRequested event,
    Emitter<LeadListState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore || state.isInitialLoading) {
      return;
    }

    final requestToken = ++_requestToken;
    emit(
      state.copyWith(
        status: LeadListLoadStatus.loadingMore,
        clearFailure: true,
      ),
    );
    final result = await listLeads(
      organizationId: state.organizationId,
      companyId: state.companyId,
      filters: state.filters,
      searchQuery: state.searchQuery,
      cursor: state.nextCursor,
      limit: pageSize,
    );
    if (emit.isDone || requestToken != _requestToken) return;
    switch (result) {
      case AppSuccess<LeadPageResult>(value: final page):
        emit(
          state.copyWith(
            status: LeadListLoadStatus.ready,
            leads: <Lead>[...state.leads, ...page.leads],
            hasMore: page.hasMore,
            nextCursor: page.nextCursor,
            isFromLocalCache: page.isFromLocalCache,
            clearFailure: true,
          ),
        );
      case AppFailure<LeadPageResult>(failure: final failure):
        emit(
          state.copyWith(status: LeadListLoadStatus.ready, failure: failure),
        );
    }
  }

  Future<void> _onRetried(
    LeadListRetried event,
    Emitter<LeadListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: LeadListLoadStatus.loading,
        leads: const <Lead>[],
        hasMore: false,
        clearNextCursor: true,
        clearFailure: true,
      ),
    );
    await _loadFirstPage(emit);
  }

  Future<void> _onLeadQualified(
    LeadListLeadQualified event,
    Emitter<LeadListState> emit,
  ) async {
    if (state.actionStatus == LeadListActionStatus.inProgress) return;
    emit(
      state.copyWith(
        actionStatus: LeadListActionStatus.inProgress,
        pendingActionLeadId: event.leadId,
        clearActionFailure: true,
      ),
    );
    final result = await qualifyLead(
      organizationId: state.organizationId,
      id: event.leadId,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Lead>(value: final updated):
        emit(
          state.copyWith(
            leads: _replaceLead(updated),
            actionStatus: LeadListActionStatus.idle,
            clearPendingActionLeadId: true,
            clearActionFailure: true,
          ),
        );
      case AppFailure<Lead>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: LeadListActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  Future<void> _onLeadDisqualified(
    LeadListLeadDisqualified event,
    Emitter<LeadListState> emit,
  ) async {
    if (state.actionStatus == LeadListActionStatus.inProgress) return;
    emit(
      state.copyWith(
        actionStatus: LeadListActionStatus.inProgress,
        pendingActionLeadId: event.leadId,
        clearActionFailure: true,
      ),
    );
    final result = await disqualifyLead(
      organizationId: state.organizationId,
      id: event.leadId,
      reason: event.reason,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<Lead>(value: final updated):
        emit(
          state.copyWith(
            leads: _replaceLead(updated),
            actionStatus: LeadListActionStatus.idle,
            clearPendingActionLeadId: true,
            clearActionFailure: true,
          ),
        );
      case AppFailure<Lead>(failure: final failure):
        emit(
          state.copyWith(
            actionStatus: LeadListActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  void _onActionDismissed(
    LeadListActionDismissed event,
    Emitter<LeadListState> emit,
  ) {
    emit(
      state.copyWith(
        actionStatus: LeadListActionStatus.idle,
        clearPendingActionLeadId: true,
        clearActionFailure: true,
      ),
    );
  }

  List<Lead> _replaceLead(Lead updated) {
    return <Lead>[
      for (final lead in state.leads) lead.id == updated.id ? updated : lead,
    ];
  }

  Future<void> _loadFirstPage(Emitter<LeadListState> emit) async {
    final requestToken = ++_requestToken;
    final result = await listLeads(
      organizationId: state.organizationId,
      companyId: state.companyId,
      filters: state.filters,
      searchQuery: state.searchQuery,
      limit: pageSize,
    );
    if (emit.isDone || requestToken != _requestToken) return;
    switch (result) {
      case AppSuccess<LeadPageResult>(value: final page):
        emit(
          state.copyWith(
            status: LeadListLoadStatus.ready,
            leads: page.leads,
            hasMore: page.hasMore,
            nextCursor: page.nextCursor,
            isFromLocalCache: page.isFromLocalCache,
            clearFailure: true,
          ),
        );
      case AppFailure<LeadPageResult>(failure: final failure):
        emit(
          state.copyWith(
            status: LeadListLoadStatus.failure,
            leads: const <Lead>[],
            hasMore: false,
            clearNextCursor: true,
            failure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }
}
