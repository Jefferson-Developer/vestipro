import 'package:freezed_annotation/freezed_annotation.dart';

import '../lead_status_transition_rules.dart';
import '../value_objects/lead_source.dart';
import '../value_objects/lead_status.dart';
import '../value_objects/lead_sync_status.dart';

part 'lead.freezed.dart';

/// Lead model for EPIC-07 (CRM), the entry point of the commercial funnel.
///
/// The tenant field [organizationId] is immutable after creation. Business
/// code must resolve it from the authenticated session, never from a form
/// field. [document] is optional because not every lead has a confirmed
/// CNPJ/CPF at capture time.
///
/// Conversion is irreversible: once [status] becomes [LeadStatus.converted]
/// it never returns to [LeadStatus.newLead]/[LeadStatus.qualified], and the
/// originating link is preserved through [convertedCustomerId] and/or
/// [convertedOpportunityId].
@freezed
abstract class Lead with _$Lead {
  const Lead._();

  const factory Lead({
    required String id,
    required String organizationId,
    String? companyId,
    required String name,
    String? document,
    required LeadSource source,
    required String responsibleUserId,
    required LeadStatus status,
    @Default(0) int score,
    String? disqualificationReason,
    String? convertedCustomerId,
    String? convertedOpportunityId,
    required DateTime createdAt,
    DateTime? contactedAt,
    DateTime? qualifiedAt,
    DateTime? convertedAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    required int version,
    required LeadSyncStatus syncStatus,
  }) = _Lead;

  /// Whether the domain FSM allows moving from [status] to [target].
  bool canTransitionTo(LeadStatus target) {
    return isValidLeadStatusTransition(status, target);
  }
}
