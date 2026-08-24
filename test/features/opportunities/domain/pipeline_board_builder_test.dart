import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

void main() {
  group('buildPipelineColumns', () {
    test('orders columns by PipelineStage.order regardless of input order', () {
      final columns = buildPipelineColumns(
        stages: <PipelineStage>[
          _stage(id: 'stage-b', order: 1),
          _stage(id: 'stage-a', order: 0),
        ],
        opportunities: const <Opportunity>[],
      );

      expect(columns.map((column) => column.stage.id).toList(), <String>[
        'stage-a',
        'stage-b',
      ]);
    });

    test(
      'a routine stage only counts open opportunities toward active count/value',
      () {
        final stage = _stage(id: 'stage-a', order: 0);
        final columns = buildPipelineColumns(
          stages: <PipelineStage>[stage],
          opportunities: <Opportunity>[
            _opportunity(
              id: 'opp-open',
              stageId: 'stage-a',
              status: OpportunityStatus.open,
              estimatedValue: 1000,
            ),
            _opportunity(
              id: 'opp-won',
              stageId: 'stage-a',
              status: OpportunityStatus.won,
              estimatedValue: 500,
            ),
          ],
        );

        final column = columns.single;
        expect(column.opportunities.length, 2);
        expect(column.activeCount, 1);
        expect(column.activeValueTotal, 1000);
      },
    );

    test(
      'a "won" terminal stage only counts opportunities whose status is won',
      () {
        final wonStage = _stage(
          id: 'stage-won',
          order: 1,
          terminalType: PipelineStageTerminalType.won,
        );
        final columns = buildPipelineColumns(
          stages: <PipelineStage>[wonStage],
          opportunities: <Opportunity>[
            _opportunity(
              id: 'opp-won',
              stageId: 'stage-won',
              status: OpportunityStatus.won,
              estimatedValue: 2000,
            ),
            _opportunity(
              id: 'opp-lost',
              stageId: 'stage-won',
              status: OpportunityStatus.lost,
              estimatedValue: 300,
            ),
          ],
        );

        final column = columns.single;
        expect(column.activeCount, 1);
        expect(column.activeValueTotal, 2000);
      },
    );

    test('an opportunity is placed in the column matching its stageId', () {
      final columns = buildPipelineColumns(
        stages: <PipelineStage>[
          _stage(id: 'stage-a', order: 0),
          _stage(id: 'stage-b', order: 1),
        ],
        opportunities: <Opportunity>[
          _opportunity(
            id: 'opp-1',
            stageId: 'stage-b',
            status: OpportunityStatus.open,
            estimatedValue: 100,
          ),
        ],
      );

      expect(columns[0].opportunities, isEmpty);
      expect(columns[1].opportunities.single.id, 'opp-1');
    });
  });
}

PipelineStage _stage({
  required String id,
  required int order,
  PipelineStageTerminalType terminalType = PipelineStageTerminalType.none,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PipelineStage(
    id: id,
    organizationId: 'org-1',
    name: 'Estagio $id',
    order: order,
    colorHex: '#2563EB',
    terminalType: terminalType,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
  );
}

Opportunity _opportunity({
  required String id,
  required String stageId,
  required OpportunityStatus status,
  required double estimatedValue,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Opportunity(
    id: id,
    organizationId: 'org-1',
    title: 'Oportunidade $id',
    customerId: 'customer-1',
    estimatedValue: estimatedValue,
    probability: 50,
    revenueForecast: estimatedValue / 2,
    responsibleUserId: 'user-1',
    stageId: stageId,
    status: status,
    expectedCloseDate: DateTime.utc(2026, 2, 1),
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: OpportunitySyncStatus.pending,
  );
}
