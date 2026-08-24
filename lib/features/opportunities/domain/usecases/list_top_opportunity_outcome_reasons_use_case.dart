import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/opportunity.dart';
import '../entities/opportunity_outcome_reason.dart';
import '../entities/opportunity_outcome_reason_usage.dart';
import '../repositories/opportunity_outcome_reason_repository.dart';
import '../repositories/opportunity_repository.dart';
import '../value_objects/opportunity_outcome_type.dart';
import '../value_objects/opportunity_status.dart';

@injectable
final class ListTopOpportunityOutcomeReasonsUseCase {
  ListTopOpportunityOutcomeReasonsUseCase(
    this._reasonRepository,
    this._opportunityRepository,
  );

  final OpportunityOutcomeReasonRepository _reasonRepository;
  final OpportunityRepository _opportunityRepository;

  Future<AppResult<List<OpportunityOutcomeReasonUsage>>> call({
    required String organizationId,
    OpportunityOutcomeType? type,
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (to.isBefore(from)) {
      fieldErrors['period'] = 'Period end must be after start.';
    }
    if (limit <= 0) {
      fieldErrors['limit'] = 'Limit must be greater than zero.';
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<OpportunityOutcomeReasonUsage>>(
        ValidationFailure(
          'Invalid outcome reason ranking payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_opportunity_outcome_reason_ranking_payload',
        ),
      );
    }

    final reasonsResult = await _reasonRepository.listByOrganization(
      organizationId: trimmedOrganizationId,
      type: type,
      includeInactive: true,
    );
    if (reasonsResult is AppFailure<List<OpportunityOutcomeReason>>) {
      return AppFailure<List<OpportunityOutcomeReasonUsage>>(
        reasonsResult.failure,
      );
    }

    final opportunitiesResult = await _opportunityRepository.listByOrganization(
      organizationId: trimmedOrganizationId,
    );
    if (opportunitiesResult is AppFailure<List<Opportunity>>) {
      return AppFailure<List<OpportunityOutcomeReasonUsage>>(
        opportunitiesResult.failure,
      );
    }

    final reasons =
        (reasonsResult as AppSuccess<List<OpportunityOutcomeReason>>).value;
    final opportunities =
        (opportunitiesResult as AppSuccess<List<Opportunity>>).value;
    final reasonById = <String, OpportunityOutcomeReason>{
      for (final reason in reasons) reason.id: reason,
    };
    final counts = <String, int>{};
    final snapshots = <String, String>{};
    final types = <String, OpportunityOutcomeType>{};

    for (final opportunity in opportunities) {
      final outcome = _outcomeFor(opportunity);
      if (outcome == null || (type != null && outcome != type)) continue;
      final closedAt = opportunity.closedAt;
      if (closedAt == null || closedAt.isBefore(from) || closedAt.isAfter(to)) {
        continue;
      }

      final reasonId = _reasonIdFor(opportunity, outcome);
      if (reasonId == null) continue;
      counts.update(reasonId, (count) => count + 1, ifAbsent: () => 1);
      types[reasonId] = outcome;
      snapshots[reasonId] =
          reasonById[reasonId]?.description ??
          _reasonSnapshotFor(opportunity, outcome) ??
          reasonId;
    }

    final ranking =
        counts.entries
            .map(
              (entry) => OpportunityOutcomeReasonUsage(
                reasonId: entry.key,
                description: snapshots[entry.key]!,
                type: types[entry.key]!,
                count: entry.value,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) {
            final countComparison = b.count.compareTo(a.count);
            if (countComparison != 0) return countComparison;
            return a.description.compareTo(b.description);
          });

    return AppSuccess<List<OpportunityOutcomeReasonUsage>>(
      ranking.take(limit).toList(growable: false),
    );
  }

  OpportunityOutcomeType? _outcomeFor(Opportunity opportunity) {
    return switch (opportunity.status) {
      OpportunityStatus.won => OpportunityOutcomeType.won,
      OpportunityStatus.lost => OpportunityOutcomeType.lost,
      OpportunityStatus.open => null,
    };
  }

  String? _reasonIdFor(
    Opportunity opportunity,
    OpportunityOutcomeType outcome,
  ) {
    return switch (outcome) {
      OpportunityOutcomeType.won => opportunity.wonReasonId,
      OpportunityOutcomeType.lost => opportunity.lostReasonId,
    };
  }

  String? _reasonSnapshotFor(
    Opportunity opportunity,
    OpportunityOutcomeType outcome,
  ) {
    return switch (outcome) {
      OpportunityOutcomeType.won => opportunity.wonReason,
      OpportunityOutcomeType.lost => opportunity.lostReason,
    };
  }
}
