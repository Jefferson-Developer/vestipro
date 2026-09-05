import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/dashboards/dashboards.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

void main() {
  const build = BuildFunnelDashboardSnapshotUseCase();
  final now = DateTime.utc(2026, 9, 10);
  final stages = <PipelineStage>[
    _stage('proposal', 'Proposta', 1),
    _stage('qualification', 'Qualificação', 0),
    _stage('lost', 'Perdida', 2, terminal: PipelineStageTerminalType.lost),
  ];

  test(
    'keeps an empty configurable stage and calculates conversion/weighted pipeline',
    () {
      final result = build(
        stages: stages,
        opportunities: <Opportunity>[
          _opportunity('a', 'qualification', value: 1000, probability: 50),
          _opportunity('b', 'qualification', value: 500, probability: 20),
        ],
        now: now,
      );

      expect(result.stages.map((row) => row.stageId), <String>[
        'qualification',
        'proposal',
        'lost',
      ]);
      expect(result.stages[1].opportunityCount, 0);
      expect(result.stages.first.conversionToNext, 0);
      expect(result.pipelineWeightedValue, 600);
      expect(result.stages.first.totalValue, 1500);
    },
  );

  test('aging ignores won/lost opportunities and averages only open ones', () {
    final result = build(
      stages: stages,
      opportunities: <Opportunity>[
        _opportunity(
          'open',
          'qualification',
          updatedAt: now.subtract(const Duration(days: 6)),
        ),
        _opportunity(
          'won',
          'qualification',
          status: OpportunityStatus.won,
          updatedAt: now.subtract(const Duration(days: 90)),
        ),
      ],
      now: now,
    );
    expect(result.stages.first.averageAgingDays, 6);
  });

  test('ranks loss reasons and filters them by loss stage', () {
    final opportunities = <Opportunity>[
      _opportunity(
        '1',
        'lost',
        status: OpportunityStatus.lost,
        lostReasonId: 'price',
        lostReason: 'Preço',
      ),
      _opportunity(
        '2',
        'lost',
        status: OpportunityStatus.lost,
        lostReasonId: 'price',
        lostReason: 'Preço',
      ),
      _opportunity(
        '3',
        'lost',
        status: OpportunityStatus.lost,
        lostReasonId: 'timing',
        lostReason: 'Momento',
        outcomeFromStageId: 'proposal',
      ),
    ];
    final result = build(
      stages: stages,
      opportunities: opportunities,
      now: now,
      lossStageId: 'lost',
    );
    expect(result.lossReasons, hasLength(1));
    expect(result.lossReasons.single.description, 'Preço');
    expect(result.lossReasons.single.count, 2);
  });
}

PipelineStage _stage(
  String id,
  String name,
  int order, {
  PipelineStageTerminalType terminal = PipelineStageTerminalType.none,
}) => PipelineStage(
  id: id,
  organizationId: 'org-1',
  name: name,
  order: order,
  colorHex: '#336699',
  terminalType: terminal,
  createdAt: DateTime.utc(2026),
  createdBy: 'admin',
  updatedAt: DateTime.utc(2026),
  updatedBy: 'admin',
  version: 1,
);

Opportunity _opportunity(
  String id,
  String stageId, {
  double value = 100,
  int probability = 50,
  OpportunityStatus status = OpportunityStatus.open,
  DateTime? updatedAt,
  String? lostReasonId,
  String? lostReason,
  String? outcomeFromStageId,
}) => Opportunity(
  id: id,
  organizationId: 'org-1',
  companyId: 'company-1',
  title: id,
  customerId: 'customer-1',
  estimatedValue: value,
  probability: probability,
  revenueForecast: value * probability / 100,
  responsibleUserId: 'rep-1',
  stageId: stageId,
  outcomeFromStageId: outcomeFromStageId,
  status: status,
  expectedCloseDate: DateTime.utc(2026, 10),
  lostReasonId: lostReasonId,
  lostReason: lostReason,
  closedAt: status == OpportunityStatus.open ? null : DateTime.utc(2026, 9, 5),
  createdAt: DateTime.utc(2026),
  createdBy: 'rep-1',
  updatedAt: updatedAt ?? DateTime.utc(2026, 9, 9),
  updatedBy: 'rep-1',
  version: 1,
  syncStatus: OpportunitySyncStatus.synced,
);
