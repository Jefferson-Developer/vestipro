import 'package:injectable/injectable.dart';

import '../entities/ranking_board.dart';
import '../entities/ranking_entry.dart';
import '../entities/ranking_participant.dart';
import '../value_objects/ranking_access_level.dart';

/// Pure ranking/tie-break/RBAC-redaction computation for TASK-118 (EPIC-15):
/// given every peer's [RankingParticipant] for one compared period, produces
/// the [RankingBoard] the caller is actually allowed to see.
///
/// This is the exact specification of the future server-side aggregation the
/// task's scope asks for ("criar agregação server-side que produz a lista
/// ordenada de atingimento") — same documented precedent as
/// `PositivacaoCalculationService`/`CustomerScoringService`: a pure,
/// trivially unit-testable function today, ready to be ported verbatim into
/// a Cloud Function once one exists for EPIC-15 (see TASK-116/TASK-117's own
/// "achievedValueCache stays null" pendency, still true here). Never itself
/// queries anything — every [RankingParticipant] must already carry the
/// server-computed `achievedValueCache`-backed value
/// `RankingDashboardCubit` resolved via the same
/// `TargetAchievementRepository` TASK-116 already reads from — never a
/// client-side sum of raw order documents.
///
/// The RBAC redaction in [compute] is the enforcement point the task
/// requires to live in the "camada de aplicação/backend, não apenas
/// oculta[ção] na UI": [RankingBoard.entries] never contains a peer's name
/// or value the resolved [RankingAccessLevel] does not allow, regardless of
/// what the presentation layer chooses to render.
@injectable
final class RankingCalculationService {
  const RankingCalculationService();

  /// Builds the [RankingBoard] for [participants] (already scoped to the
  /// peers the caller's role/team is allowed to be compared against — that
  /// scoping is `RankingPeerResolverService`'s job, not this service's),
  /// under [accessLevel] (`RankingAccessLevel.resolve`'s result), locating
  /// [currentUserDimensionId] among them for highlighting.
  ///
  /// Deterministic tie-break, documented per the task's own requirement:
  /// 1. [RankingEntry.achievementPercentage], descending.
  /// 2. [RankingEntry.realizedValue], descending (absolute value, same
  ///    metric unit for every participant of one ranking).
  /// 3. [RankingEntry.displayName], ascending, case-insensitive.
  /// 4. [RankingEntry.dimensionId], ascending — the final, always-unique
  ///    tie-break so two participants can never resolve to the same rank
  ///    even with an identical name.
  RankingBoard compute({
    required List<RankingParticipant> participants,
    required String currentUserDimensionId,
    required RankingAccessLevel accessLevel,
  }) {
    final calculated = participants
        .where((participant) => participant.isCalculated)
        .toList();

    final ranked = calculated.map((participant) {
      final realizedValue = participant.realizedValue!;
      return _RankedCandidate(
        dimensionId: participant.dimensionId,
        displayName: participant.displayName,
        realizedValue: realizedValue,
        targetValue: participant.targetValue,
        achievementPercentage: _percentageOf(
          realizedValue,
          participant.targetValue,
        ),
      );
    }).toList()..sort(_compareCandidates);

    final entries = <RankingEntry>[
      for (var index = 0; index < ranked.length; index++)
        RankingEntry(
          rank: index + 1,
          dimensionId: ranked[index].dimensionId,
          displayName: ranked[index].displayName,
          achievementPercentage: ranked[index].achievementPercentage,
          realizedValue: ranked[index].realizedValue,
          targetValue: ranked[index].targetValue,
          isCurrentUser: ranked[index].dimensionId == currentUserDimensionId,
        ),
    ];

    RankingEntry? currentUserEntry;
    for (final entry in entries) {
      if (entry.isCurrentUser) {
        currentUserEntry = entry;
        break;
      }
    }

    final visibleEntries = accessLevel == RankingAccessLevel.full
        ? entries
        : <RankingEntry>[?currentUserEntry];

    return RankingBoard(
      accessLevel: accessLevel,
      entries: visibleEntries,
      totalParticipants: entries.length,
      currentUserRank: currentUserEntry?.rank,
    );
  }

  int _compareCandidates(_RankedCandidate a, _RankedCandidate b) {
    final byPercentage = b.achievementPercentage.compareTo(
      a.achievementPercentage,
    );
    if (byPercentage != 0) return byPercentage;

    final byValue = b.realizedValue.compareTo(a.realizedValue);
    if (byValue != 0) return byValue;

    final byName = a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    );
    if (byName != 0) return byName;

    return a.dimensionId.compareTo(b.dimensionId);
  }

  double _percentageOf(double realizedValue, double targetValue) {
    if (targetValue == 0) return realizedValue > 0 ? 100.0 : 0.0;
    return (realizedValue / targetValue) * 100;
  }
}

final class _RankedCandidate {
  const _RankedCandidate({
    required this.dimensionId,
    required this.displayName,
    required this.realizedValue,
    required this.targetValue,
    required this.achievementPercentage,
  });

  final String dimensionId;
  final String displayName;
  final double realizedValue;
  final double targetValue;
  final double achievementPercentage;
}
