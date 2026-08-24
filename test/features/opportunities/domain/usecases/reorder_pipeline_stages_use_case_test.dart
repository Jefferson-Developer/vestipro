import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockPipelineStageRepository extends Mock
    implements PipelineStageRepository {}

void main() {
  group('ReorderPipelineStagesUseCase', () {
    late _MockPipelineStageRepository repository;
    late ReorderPipelineStagesUseCase useCase;

    setUp(() {
      repository = _MockPipelineStageRepository();
      useCase = ReorderPipelineStagesUseCase(repository);
    });

    test(
      'delegates to the repository when the id set matches exactly',
      () async {
        when(
          () => repository.listByOrganization(
            organizationId: any(named: 'organizationId'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<PipelineStage>>(<PipelineStage>[
            _stage(id: 'stage-a', order: 0),
            _stage(id: 'stage-b', order: 1),
          ]),
        );
        when(
          () => repository.reorder(
            organizationId: any(named: 'organizationId'),
            orderedStageIds: any(named: 'orderedStageIds'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<PipelineStage>>(<PipelineStage>[
            _stage(id: 'stage-b', order: 0),
            _stage(id: 'stage-a', order: 1),
          ]),
        );

        final result = await useCase.call(
          organizationId: 'org-1',
          orderedStageIds: <String>['stage-b', 'stage-a'],
          updatedBy: 'user-1',
        );

        expect(result, isA<AppSuccess<List<PipelineStage>>>());
        verify(
          () => repository.reorder(
            organizationId: 'org-1',
            orderedStageIds: <String>['stage-b', 'stage-a'],
            updatedBy: 'user-1',
          ),
        ).called(1);
      },
    );

    test('rejects a partial id set without touching reorder', () async {
      when(
        () => repository.listByOrganization(
          organizationId: any(named: 'organizationId'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<PipelineStage>>(<PipelineStage>[
          _stage(id: 'stage-a', order: 0),
          _stage(id: 'stage-b', order: 1),
        ]),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        orderedStageIds: <String>['stage-a'],
        updatedBy: 'user-1',
      );

      expect(result, isA<AppFailure<List<PipelineStage>>>());
      expect(
        (result as AppFailure<List<PipelineStage>>).failure.code,
        'invalid_pipeline_stage_reorder_set',
      );
      verifyNever(
        () => repository.reorder(
          organizationId: any(named: 'organizationId'),
          orderedStageIds: any(named: 'orderedStageIds'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });

    test('rejects an unknown id without touching reorder', () async {
      when(
        () => repository.listByOrganization(
          organizationId: any(named: 'organizationId'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<PipelineStage>>(<PipelineStage>[
          _stage(id: 'stage-a', order: 0),
        ]),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        orderedStageIds: <String>['stage-unknown'],
        updatedBy: 'user-1',
      );

      expect(result, isA<AppFailure<List<PipelineStage>>>());
      verifyNever(
        () => repository.reorder(
          organizationId: any(named: 'organizationId'),
          orderedStageIds: any(named: 'orderedStageIds'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });
  });
}

PipelineStage _stage({required String id, required int order}) {
  final now = DateTime.utc(2026, 1, 1);
  return PipelineStage(
    id: id,
    organizationId: 'org-1',
    name: 'Estagio $id',
    order: order,
    colorHex: '#2563EB',
    terminalType: PipelineStageTerminalType.none,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
  );
}
