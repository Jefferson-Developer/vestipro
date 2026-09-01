import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('RankingCalculationService.compute', () {
    const service = RankingCalculationService();

    test('sorts by achievement percentage descending', () {
      final board = service.compute(
        participants: <RankingParticipant>[
          const RankingParticipant(
            dimensionId: 'rep-1',
            displayName: 'Ana',
            targetValue: 1000,
            realizedValue: 500,
          ),
          const RankingParticipant(
            dimensionId: 'rep-2',
            displayName: 'Bruno',
            targetValue: 1000,
            realizedValue: 900,
          ),
          const RankingParticipant(
            dimensionId: 'rep-3',
            displayName: 'Carla',
            targetValue: 1000,
            realizedValue: 200,
          ),
        ],
        currentUserDimensionId: 'rep-2',
        accessLevel: RankingAccessLevel.full,
      );

      expect(board.entries.map((e) => e.dimensionId).toList(), <String>[
        'rep-2',
        'rep-1',
        'rep-3',
      ]);
      expect(board.entries.map((e) => e.rank).toList(), <int>[1, 2, 3]);
      expect(board.totalParticipants, 3);
      expect(board.currentUserRank, 1);
      expect(board.entries.first.isCurrentUser, isTrue);
    });

    test('tie-break: same achievement % resolved by absolute value '
        'descending', () {
      final board = service.compute(
        participants: <RankingParticipant>[
          const RankingParticipant(
            dimensionId: 'rep-1',
            displayName: 'Ana',
            targetValue: 1000,
            realizedValue: 500,
          ),
          const RankingParticipant(
            dimensionId: 'rep-2',
            displayName: 'Bruno',
            targetValue: 2000,
            realizedValue: 1000,
          ),
        ],
        currentUserDimensionId: 'rep-1',
        accessLevel: RankingAccessLevel.full,
      );

      // Both are at 50% achievement — rep-2's higher absolute value must win.
      expect(board.entries.map((e) => e.dimensionId).toList(), <String>[
        'rep-2',
        'rep-1',
      ]);
    });

    test('tie-break: same % and same absolute value resolved by name '
        'ascending, case-insensitive', () {
      final board = service.compute(
        participants: <RankingParticipant>[
          const RankingParticipant(
            dimensionId: 'rep-1',
            displayName: 'zeca',
            targetValue: 1000,
            realizedValue: 500,
          ),
          const RankingParticipant(
            dimensionId: 'rep-2',
            displayName: 'Ana',
            targetValue: 1000,
            realizedValue: 500,
          ),
        ],
        currentUserDimensionId: '',
        accessLevel: RankingAccessLevel.full,
      );

      expect(board.entries.map((e) => e.dimensionId).toList(), <String>[
        'rep-2',
        'rep-1',
      ]);
    });

    test('tie-break: identical % and value and name resolved by dimensionId '
        'ascending — always deterministic', () {
      final board = service.compute(
        participants: <RankingParticipant>[
          const RankingParticipant(
            dimensionId: 'rep-b',
            displayName: 'Ana',
            targetValue: 1000,
            realizedValue: 500,
          ),
          const RankingParticipant(
            dimensionId: 'rep-a',
            displayName: 'Ana',
            targetValue: 1000,
            realizedValue: 500,
          ),
        ],
        currentUserDimensionId: '',
        accessLevel: RankingAccessLevel.full,
      );

      expect(board.entries.map((e) => e.dimensionId).toList(), <String>[
        'rep-a',
        'rep-b',
      ]);
    });

    test('excludes participants with no calculated achievement from ranking '
        'and totalParticipants', () {
      final board = service.compute(
        participants: <RankingParticipant>[
          const RankingParticipant(
            dimensionId: 'rep-1',
            displayName: 'Ana',
            targetValue: 1000,
            realizedValue: 500,
          ),
          const RankingParticipant(
            dimensionId: 'rep-2',
            displayName: 'Bruno',
            targetValue: 1000,
          ),
        ],
        currentUserDimensionId: 'rep-2',
        accessLevel: RankingAccessLevel.full,
      );

      expect(board.totalParticipants, 1);
      expect(board.entries.map((e) => e.dimensionId), <String>['rep-1']);
      expect(
        board.currentUserRank,
        isNull,
        reason: 'rep-2 has no calculated achievement so cannot be ranked.',
      );
    });

    group('RBAC redaction (RankingAccessLevel)', () {
      final participants = <RankingParticipant>[
        const RankingParticipant(
          dimensionId: 'rep-1',
          displayName: 'Ana',
          targetValue: 1000,
          realizedValue: 900,
        ),
        const RankingParticipant(
          dimensionId: 'rep-2',
          displayName: 'Bruno',
          targetValue: 1000,
          realizedValue: 500,
        ),
        const RankingParticipant(
          dimensionId: 'rep-3',
          displayName: 'Carla',
          targetValue: 1000,
          realizedValue: 200,
        ),
      ];

      test('full access (SALES_MANAGER/ADMIN/OWNER, or an opted-in org): every '
          'peer\'s name and value are returned', () {
        final board = service.compute(
          participants: participants,
          currentUserDimensionId: 'rep-2',
          accessLevel: RankingAccessLevel.full,
        );

        expect(board.entries, hasLength(3));
        expect(
          board.entries.map((e) => e.displayName),
          containsAll(<String>['Ana', 'Bruno', 'Carla']),
        );
        expect(board.totalParticipants, 3);
        expect(board.currentUserRank, 2);
      });

      test('relativePositionOnly (SALES_REP under an org that restricts '
          'ranking): only the caller\'s own entry is returned — never another '
          'peer\'s name or value', () {
        final board = service.compute(
          participants: participants,
          currentUserDimensionId: 'rep-2',
          accessLevel: RankingAccessLevel.relativePositionOnly,
        );

        expect(board.entries, hasLength(1));
        expect(board.entries.single.dimensionId, 'rep-2');
        expect(board.entries.single.isCurrentUser, isTrue);
        // The count is safe to reveal (identifies nobody), the rank is the
        // caller's own — but no other participant's name/value is ever
        // present in `entries`.
        expect(board.totalParticipants, 3);
        expect(board.currentUserRank, 2);
        expect(
          board.entries.any((e) => e.displayName == 'Ana'),
          isFalse,
          reason: 'rep-1 (Ana) must never leak into a redacted board.',
        );
        expect(
          board.entries.any((e) => e.displayName == 'Carla'),
          isFalse,
          reason: 'rep-3 (Carla) must never leak into a redacted board.',
        );
      });

      test(
        'relativePositionOnly when the caller has no calculated achievement: '
        'entries is empty, but rank/total are still meaningful for peers',
        () {
          final board = service.compute(
            participants: participants,
            currentUserDimensionId: 'someone-not-ranked',
            accessLevel: RankingAccessLevel.relativePositionOnly,
          );

          expect(board.entries, isEmpty);
          expect(board.currentUserRank, isNull);
          expect(board.totalParticipants, 3);
        },
      );
    });

    group('RankingAccessLevel.resolve', () {
      test('SALES_MANAGER/ADMIN/OWNER (allOrganization/teams) always resolve '
          'to full, regardless of the organization setting', () {
        expect(
          RankingAccessLevel.resolve(
            mode: TargetVisibilityMode.allOrganization,
            organizationSetting: RankingVisibilityMode.relativePositionOnly,
          ),
          RankingAccessLevel.full,
        );
        expect(
          RankingAccessLevel.resolve(
            mode: TargetVisibilityMode.teams,
            organizationSetting: RankingVisibilityMode.relativePositionOnly,
          ),
          RankingAccessLevel.full,
        );
      });

      test('SALES_REP (ownOnly) resolves per the organization setting', () {
        expect(
          RankingAccessLevel.resolve(
            mode: TargetVisibilityMode.ownOnly,
            organizationSetting: RankingVisibilityMode.fullRanking,
          ),
          RankingAccessLevel.full,
        );
        expect(
          RankingAccessLevel.resolve(
            mode: TargetVisibilityMode.ownOnly,
            organizationSetting: RankingVisibilityMode.relativePositionOnly,
          ),
          RankingAccessLevel.relativePositionOnly,
        );
      });
    });
  });
}
