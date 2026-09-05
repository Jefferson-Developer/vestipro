import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/reports/reports.dart';

class _MockSavedReportRepository extends Mock
    implements SavedReportRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockReportScheduleReferenceChecker extends Mock
    implements ReportScheduleReferenceChecker {}

void main() {
  late _MockSavedReportRepository repository;
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _MockReportScheduleReferenceChecker scheduleReferenceChecker;

  const organizationId = 'org-1';
  const companyId = 'company-1';

  final definition = ReportDefinition(
    organizationId: organizationId,
    companyId: companyId,
    dimensions: const <String>['seller'],
    metrics: const <String>['revenueGross'],
    groupBy: const <String>['seller'],
  );

  Membership buildMembership(
    String userId,
    String roleName, {
    List<String> teamIds = const <String>[],
  }) {
    return Membership(
      id: userId,
      organizationId: organizationId,
      userId: userId,
      roleId: roleName,
      roleName: roleName,
      teamIds: teamIds,
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: userId,
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: userId,
    );
  }

  SavedReport buildSavedReport({
    String id = 'report-1',
    String ownerId = 'rep-a',
    String name = 'Minhas vendas',
    SavedReportVisibility visibility = SavedReportVisibility.private,
    List<String> sharedWithTeamIds = const <String>[],
    bool favorite = false,
  }) {
    return SavedReport(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      ownerId: ownerId,
      name: name,
      definition: definition,
      visibility: visibility,
      sharedWithTeamIds: sharedWithTeamIds,
      favorite: favorite,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: ownerId,
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: ownerId,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      SavedReport(
        id: 'fallback',
        organizationId: organizationId,
        companyId: companyId,
        ownerId: 'fallback',
        name: 'fallback',
        definition: definition,
        visibility: SavedReportVisibility.private,
        favorite: false,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'fallback',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'fallback',
      ),
    );
  });

  setUp(() {
    repository = _MockSavedReportRepository();
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    scheduleReferenceChecker = _MockReportScheduleReferenceChecker();
  });

  group('SaveReportView', () {
    late SaveReportView useCase;

    setUp(() {
      useCase = SaveReportView(
        repository,
        membershipRepository,
        permissionService,
        const Uuid(),
      );
    });

    test(
      'SALES_REP saves a private view without needing any capability',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
        );
        when(
          () => repository.listOwned(
            organizationId: organizationId,
            companyId: companyId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async => const AppSuccess<List<SavedReport>>(<SavedReport>[]),
        );
        when(() => repository.create(any())).thenAnswer(
          (invocation) async => AppSuccess<SavedReport>(
            invocation.positionalArguments.first as SavedReport,
          ),
        );

        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          ownerId: 'rep-a',
          name: 'Minhas vendas',
          definition: definition,
        );

        expect(result, isA<AppSuccess<SavedReport>>());
        final saved = (result as AppSuccess<SavedReport>).value;
        expect(saved.visibility, SavedReportVisibility.private);
        expect(saved.sharedWithTeamIds, isEmpty);
      },
    );

    test('SALES_REP (report.share.team) saves a team-shared view and snapshots '
        "the owner's current teamIds", () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership('rep-a', 'SALES_REP', teamIds: <String>['team-a']),
        ),
      );
      when(
        () => repository.listOwned(
          organizationId: organizationId,
          companyId: companyId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async => const AppSuccess<List<SavedReport>>(<SavedReport>[]),
      );
      when(() => repository.create(any())).thenAnswer(
        (invocation) async => AppSuccess<SavedReport>(
          invocation.positionalArguments.first as SavedReport,
        ),
      );

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        ownerId: 'rep-a',
        name: 'Vendas da equipe',
        definition: definition,
        visibility: SavedReportVisibility.team,
      );

      expect(result, isA<AppSuccess<SavedReport>>());
      final saved = (result as AppSuccess<SavedReport>).value;
      expect(saved.visibility, SavedReportVisibility.team);
      expect(saved.sharedWithTeamIds, <String>['team-a']);
    });

    test('SALES_REP cannot save a view shared with the whole organization '
        '(caps out at team, PermissionFailure)', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
      );

      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        ownerId: 'rep-a',
        name: 'Vendas globais',
        definition: definition,
        visibility: SavedReportVisibility.organization,
      );

      expect(result, isA<AppFailure<SavedReport>>());
      expect(
        (result as AppFailure<SavedReport>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(() => repository.create(any()));
    });

    test(
      'SALES_MANAGER saves a view shared with the whole organization',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'manager-a',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership('manager-a', 'SALES_MANAGER'),
          ),
        );
        when(
          () => repository.listOwned(
            organizationId: organizationId,
            companyId: companyId,
            userId: 'manager-a',
          ),
        ).thenAnswer(
          (_) async => const AppSuccess<List<SavedReport>>(<SavedReport>[]),
        );
        when(() => repository.create(any())).thenAnswer(
          (invocation) async => AppSuccess<SavedReport>(
            invocation.positionalArguments.first as SavedReport,
          ),
        );

        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          ownerId: 'manager-a',
          name: 'Visão da diretoria',
          definition: definition,
          visibility: SavedReportVisibility.organization,
        );

        expect(result, isA<AppSuccess<SavedReport>>());
      },
    );

    test(
      'rejects a duplicate name for the same owner (ConflictFailure)',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
        );
        when(
          () => repository.listOwned(
            organizationId: organizationId,
            companyId: companyId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<SavedReport>>(<SavedReport>[
            buildSavedReport(name: 'Minhas vendas'),
          ]),
        );

        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          ownerId: 'rep-a',
          name: '  minhas vendas  ',
          definition: definition,
        );

        expect(result, isA<AppFailure<SavedReport>>());
        expect(
          (result as AppFailure<SavedReport>).failure,
          isA<ConflictFailure>(),
        );
        verifyNever(() => repository.create(any()));
      },
    );

    test('rejects a blank name without touching the repository', () async {
      final result = await useCase(
        organizationId: organizationId,
        companyId: companyId,
        ownerId: 'rep-a',
        name: '   ',
        definition: definition,
      );

      expect(result, isA<AppFailure<SavedReport>>());
      expect(
        (result as AppFailure<SavedReport>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => membershipRepository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });

  group('UpdateSavedReport', () {
    late UpdateSavedReport useCase;

    setUp(() {
      useCase = UpdateSavedReport(
        repository,
        membershipRepository,
        permissionService,
      );
    });

    test('owner renames their own private report', () async {
      final current = buildSavedReport(ownerId: 'rep-a');
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
      );
      when(
        () => repository.listOwned(
          organizationId: organizationId,
          companyId: companyId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<SavedReport>>(<SavedReport>[current]),
      );
      when(() => repository.update(any())).thenAnswer(
        (invocation) async => AppSuccess<SavedReport>(
          invocation.positionalArguments.first as SavedReport,
        ),
      );

      final result = await useCase(
        requesterId: 'rep-a',
        current: current,
        name: 'Vendas renomeadas',
      );

      expect(result, isA<AppSuccess<SavedReport>>());
      expect(
        (result as AppSuccess<SavedReport>).value.name,
        'Vendas renomeadas',
      );
    });

    test('a non-owner, non-admin with read access cannot edit a shared report '
        '(PermissionFailure)', () async {
      final current = buildSavedReport(
        ownerId: 'rep-a',
        visibility: SavedReportVisibility.team,
        sharedWithTeamIds: <String>['team-a'],
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'manager-a',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership(
            'manager-a',
            'SALES_MANAGER',
            teamIds: <String>['team-a'],
          ),
        ),
      );

      final result = await useCase(
        requesterId: 'manager-a',
        current: current,
        name: 'Tentativa indevida',
      );

      expect(result, isA<AppFailure<SavedReport>>());
      expect(
        (result as AppFailure<SavedReport>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(() => repository.update(any()));
    });

    test('ADMIN edits a report shared by someone else', () async {
      final current = buildSavedReport(
        ownerId: 'rep-a',
        visibility: SavedReportVisibility.team,
        sharedWithTeamIds: <String>['team-a'],
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'admin-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('admin-a', 'ADMIN')),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership('rep-a', 'SALES_REP', teamIds: <String>['team-a']),
        ),
      );
      when(
        () => repository.listOwned(
          organizationId: organizationId,
          companyId: companyId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<SavedReport>>(<SavedReport>[current]),
      );
      when(() => repository.update(any())).thenAnswer(
        (invocation) async => AppSuccess<SavedReport>(
          invocation.positionalArguments.first as SavedReport,
        ),
      );

      final result = await useCase(
        requesterId: 'admin-a',
        current: current,
        name: 'Renomeado pelo admin',
      );

      expect(result, isA<AppSuccess<SavedReport>>());
    });

    test('owner cannot raise their own report to organization visibility '
        'without report.share.organization (PermissionFailure)', () async {
      final current = buildSavedReport(ownerId: 'rep-a');
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
      );

      final result = await useCase(
        requesterId: 'rep-a',
        current: current,
        visibility: SavedReportVisibility.organization,
      );

      expect(result, isA<AppFailure<SavedReport>>());
      expect(
        (result as AppFailure<SavedReport>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(() => repository.update(any()));
    });
  });

  group('DeleteSavedReport', () {
    late DeleteSavedReport useCase;

    setUp(() {
      useCase = DeleteSavedReport(
        repository,
        membershipRepository,
        scheduleReferenceChecker,
      );
    });

    test(
      'owner deletes their own report when no schedule references it',
      () async {
        final report = buildSavedReport(ownerId: 'rep-a');
        when(
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
        );
        when(
          () =>
              scheduleReferenceChecker.hasActiveScheduleReferencing(report.id),
        ).thenAnswer((_) async => const AppSuccess<bool>(false));
        when(
          () => repository.delete(
            organizationId: organizationId,
            reportId: report.id,
          ),
        ).thenAnswer((_) async => const AppSuccess<void>(null));

        final result = await useCase(requesterId: 'rep-a', report: report);

        expect(result, isA<AppSuccess<void>>());
      },
    );

    test('a non-owner, non-admin cannot delete a shared report', () async {
      final report = buildSavedReport(
        ownerId: 'rep-a',
        visibility: SavedReportVisibility.organization,
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-b',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-b', 'SALES_REP')),
      );

      final result = await useCase(requesterId: 'rep-b', report: report);

      expect(result, isA<AppFailure<void>>());
      expect((result as AppFailure<void>).failure, isA<PermissionFailure>());
      verifyNever(
        () => scheduleReferenceChecker.hasActiveScheduleReferencing(any()),
      );
      verifyNever(
        () => repository.delete(
          organizationId: any(named: 'organizationId'),
          reportId: any(named: 'reportId'),
        ),
      );
    });

    test('never silently deletes a report referenced by an active schedule '
        '(ConflictFailure, no repository call)', () async {
      final report = buildSavedReport(ownerId: 'rep-a');
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
      );
      when(
        () => scheduleReferenceChecker.hasActiveScheduleReferencing(report.id),
      ).thenAnswer((_) async => const AppSuccess<bool>(true));

      final result = await useCase(requesterId: 'rep-a', report: report);

      expect(result, isA<AppFailure<void>>());
      expect(
        (result as AppFailure<void>).failure,
        isA<ConflictFailure>().having(
          (failure) => failure.code,
          'code',
          'saved_report_has_active_schedule',
        ),
      );
      verifyNever(
        () => repository.delete(
          organizationId: any(named: 'organizationId'),
          reportId: any(named: 'reportId'),
        ),
      );
    });
  });

  group('ListSavedReports', () {
    test(
      'combines owned and shared reports scoped by the requester\'s teams',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership('rep-a', 'SALES_REP', teamIds: <String>['team-a']),
          ),
        );
        final owned = buildSavedReport(id: 'owned-1', ownerId: 'rep-a');
        final shared = buildSavedReport(
          id: 'shared-1',
          ownerId: 'manager-a',
          visibility: SavedReportVisibility.organization,
        );
        when(
          () => repository.listOwned(
            organizationId: organizationId,
            companyId: companyId,
            userId: 'rep-a',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<SavedReport>>(<SavedReport>[owned]),
        );
        when(
          () => repository.listSharedWithMe(
            organizationId: organizationId,
            companyId: companyId,
            userId: 'rep-a',
            teamIds: <String>['team-a'],
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<SavedReport>>(<SavedReport>[shared]),
        );

        final useCase = ListSavedReports(repository, membershipRepository);
        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          userId: 'rep-a',
        );

        expect(result, isA<AppSuccess<SavedReportsOverview>>());
        final overview = (result as AppSuccess<SavedReportsOverview>).value;
        expect(overview.owned, <SavedReport>[owned]);
        expect(overview.shared, <SavedReport>[shared]);
      },
    );
  });
}
