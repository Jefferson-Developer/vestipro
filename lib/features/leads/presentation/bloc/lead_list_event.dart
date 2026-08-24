import '../../domain/entities/lead_list_filters.dart';

sealed class LeadListEvent {
  const LeadListEvent();
}

final class LeadListStarted extends LeadListEvent {
  const LeadListStarted({
    required this.organizationId,
    this.companyId,
    required this.userId,
    this.searchQuery = '',
    this.filters = LeadListFilters.empty,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final String searchQuery;
  final LeadListFilters filters;
}

final class LeadListSearchChanged extends LeadListEvent {
  const LeadListSearchChanged(this.searchQuery);

  final String searchQuery;
}

final class LeadListSearchDebounced extends LeadListEvent {
  const LeadListSearchDebounced(this.token);

  final int token;
}

final class LeadListFiltersChanged extends LeadListEvent {
  const LeadListFiltersChanged(this.filters);

  final LeadListFilters filters;
}

final class LeadListNextPageRequested extends LeadListEvent {
  const LeadListNextPageRequested();
}

final class LeadListRetried extends LeadListEvent {
  const LeadListRetried();
}

/// Qualifies [leadId] in place. [LeadListBloc] resolves the actor from the
/// current session (`state.userId`), never from a value the caller could
/// forge — the same rule TASK-055's use cases already enforce.
final class LeadListLeadQualified extends LeadListEvent {
  const LeadListLeadQualified(this.leadId);

  final String leadId;
}

/// Disqualifies [leadId] in place, always requiring a non-empty [reason]
/// (also re-validated by `DisqualifyLeadUseCase`/the domain, never trusted
/// only because the UI blocked an empty submission).
final class LeadListLeadDisqualified extends LeadListEvent {
  const LeadListLeadDisqualified({required this.leadId, required this.reason});

  final String leadId;
  final String reason;
}

final class LeadListActionDismissed extends LeadListEvent {
  const LeadListActionDismissed();
}
