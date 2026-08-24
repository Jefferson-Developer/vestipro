import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';

class _MockPipelineStageRepository extends Mock
    implements PipelineStageRepository {}

void main() {
  group('CreatePipelineStageUseCase', () {
    late _MockPipelineStageRepository repository;
    late CreatePipelineStageUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_stage(id: 'fallback', order: 0));
    });

    setUp(() {
      repository = _MockPipelineStageRepository();
      useCase = CreatePipelineStageUseCase(repository);
    });

    test('appends the new stage at the end of the current order', () async {
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
      when(() => repository.create(stage: any(named: 'stage'))).thenAnswer((
        invocation,
      ) async {
        return AppSuccess<PipelineStage>(
          invocation.namedArguments[#stage] as PipelineStage,
        );
      });

      final result = await useCase.call(
        id: 'stage-c',
        organizationId: 'org-1',
        name: 'Negociacao',
        colorHex: '#2563EB',
        createdBy: 'user-1',
      );

      final created = (result as AppSuccess<PipelineStage>).value;
      expect(created.order, 2);
      expect(created.terminalType, PipelineStageTerminalType.none);
    });

    test(
      'rejects an invalid colorHex without touching the repository',
      () async {
        final result = await useCase.call(
          id: 'stage-c',
          organizationId: 'org-1',
          name: 'Negociacao',
          colorHex: 'blue',
          createdBy: 'user-1',
        );

        expect(result, isA<AppFailure<PipelineStage>>());
        verifyNever(
          () => repository.listByOrganization(
            organizationId: any(named: 'organizationId'),
          ),
        );
      },
    );

    test('rejects a second "won" stage in the same organization', () async {
      when(
        () => repository.listByOrganization(
          organizationId: any(named: 'organizationId'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<PipelineStage>>(<PipelineStage>[
          _stage(
            id: 'stage-won',
            order: 0,
            terminalType: PipelineStageTerminalType.won,
          ),
        ]),
      );

      final result = await useCase.call(
        id: 'stage-c',
        organizationId: 'org-1',
        name: 'Ganho 2',
        colorHex: '#16A34A',
        terminalType: PipelineStageTerminalType.won,
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<PipelineStage>>());
      expect(
        (result as AppFailure<PipelineStage>).failure.code,
        'duplicate_terminal_pipeline_stage',
      );
      verifyNever(() => repository.create(stage: any(named: 'stage')));
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
