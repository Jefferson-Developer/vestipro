import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';
import 'package:vestipro/features/organizations/organizations.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('PipelineStageAdminPage', () {
    late _MockMembershipRepository membershipRepository;
    late _InMemoryPipelineStageRepository stageRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      stageRepository = _InMemoryPipelineStageRepository();
      permissionService = PermissionService(membershipRepository);
    });

    PipelineStageAdminBloc buildBloc() {
      return PipelineStageAdminBloc(
        listStages: ListPipelineStagesUseCase(stageRepository),
        createStage: CreatePipelineStageUseCase(stageRepository),
        renameStage: RenamePipelineStageUseCase(stageRepository),
        reorderStages: ReorderPipelineStagesUseCase(stageRepository),
      );
    }

    Widget buildPage() {
      return PipelineStageAdminPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets(
      'renders forbidden for a role without pipelineStage.manage, hiding '
      'create/rename/reorder controls entirely',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'SALES_REP');
        stageRepository.seed(
          _stage(id: 'stage-a', name: 'Qualificacao', order: 0),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(ForbiddenPage), findsOneWidget);
        expect(find.text('Novo estágio'), findsNothing);
        expect(find.text('Qualificacao'), findsNothing);
        expect(find.byType(ReorderableListView), findsNothing);
      },
    );

    testWidgets(
      'renders the stage admin screen for SALES_MANAGER, with create/reorder '
      'controls available',
      (tester) async {
        _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');
        stageRepository.seed(
          _stage(id: 'stage-a', name: 'Qualificacao', order: 0),
        );

        await pumpApp(tester, buildPage());
        await tester.pumpAndSettle();

        expect(find.byType(ForbiddenPage), findsNothing);
        expect(find.text('Novo estágio'), findsOneWidget);
        expect(find.text('Qualificacao'), findsOneWidget);
        expect(find.byType(ReorderableListView), findsOneWidget);
      },
    );
  });
}

void _stubMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'current-user'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

PipelineStage _stage({
  required String id,
  required String name,
  required int order,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PipelineStage(
    id: id,
    organizationId: 'org-1',
    name: name,
    order: order,
    colorHex: '#2563EB',
    terminalType: PipelineStageTerminalType.none,
    createdAt: now,
    createdBy: 'current-user',
    updatedAt: now,
    updatedBy: 'current-user',
    version: 1,
  );
}

final class _InMemoryPipelineStageRepository
    implements PipelineStageRepository {
  final List<PipelineStage> stages = <PipelineStage>[];

  void seed(PipelineStage stage) => stages.add(stage);

  @override
  Future<AppResult<PipelineStage>> create({
    required PipelineStage stage,
  }) async {
    stages.add(stage);
    return AppSuccess<PipelineStage>(stage);
  }

  @override
  Future<AppResult<PipelineStage>> update({
    required PipelineStage stage,
  }) async {
    final index = stages.indexWhere((existing) => existing.id == stage.id);
    if (index == -1) {
      return const AppFailure<PipelineStage>(
        NotFoundFailure(
          'Pipeline stage not found.',
          code: 'pipeline_stage_not_found',
        ),
      );
    }
    stages[index] = stage;
    return AppSuccess<PipelineStage>(stage);
  }

  @override
  Future<AppResult<List<PipelineStage>>> listByOrganization({
    required String organizationId,
  }) async {
    final visible = stages
        .where((stage) => stage.organizationId == organizationId)
        .toList(growable: false);
    return AppSuccess<List<PipelineStage>>(visible);
  }

  @override
  Future<AppResult<List<PipelineStage>>> reorder({
    required String organizationId,
    required List<String> orderedStageIds,
    required String updatedBy,
  }) async {
    final byId = <String, PipelineStage>{
      for (final stage in stages) stage.id: stage,
    };
    final reordered = <PipelineStage>[
      for (var index = 0; index < orderedStageIds.length; index++)
        byId[orderedStageIds[index]]!.copyWith(order: index),
    ];
    stages
      ..clear()
      ..addAll(reordered);
    return AppSuccess<List<PipelineStage>>(reordered);
  }
}
