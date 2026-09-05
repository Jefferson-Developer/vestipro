import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/reports/reports.dart';

class _MockReportScheduleRepository extends Mock
    implements ReportScheduleRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockReportScheduleRepository repository;
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;

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

  SavedReport buildSavedReport({String ownerId = 'manager-a'}) => SavedReport(
    id: 'report-1',
    organizationId: organizationId,
    companyId: companyId,
    ownerId: ownerId,
    name: 'Vendas por vendedor',
    definition: definition,
    visibility: SavedReportVisibility.private,
    favorite: false,
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: ownerId,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: ownerId,
  );

  ReportSchedule buildSchedule({
    String createdBy = 'manager-a',
    ReportScheduleStatus status = ReportScheduleStatus.active,
  }) => ReportSchedule(
    id: 'schedule-1',
    organizationId: organizationId,
    companyId: companyId,
    savedReportId: 'report-1',
    savedReportName: 'Vendas por vendedor',
    frequency: ReportScheduleFrequency.daily,
    hour: 8,
    minute: 0,
    format: ReportExportFormat.pdf,
    recipientUserIds: const <String>['rep-a'],
    status: status,
    nextRunAt: DateTime.utc(2026, 1, 2, 11),
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: createdBy,
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: createdBy,
  );

  setUpAll(() {
    registerFallbackValue(buildSchedule());
  });

  setUp(() {
    repository = _MockReportScheduleRepository();
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
  });

  group('CreateReportSchedule', () {
    late CreateReportSchedule useCase;

    setUp(() {
      useCase = CreateReportSchedule(
        repository,
        membershipRepository,
        permissionService,
      );
    });

    test('SALES_MANAGER (report.schedule) creates a daily schedule', () async {
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
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'rep-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-a', 'SALES_REP')),
      );
      when(() => repository.create(any())).thenAnswer(
        (invocation) async => AppSuccess<ReportSchedule>(
          invocation.positionalArguments.first as ReportSchedule,
        ),
      );

      final result = await useCase(
        requesterId: 'manager-a',
        savedReport: buildSavedReport(),
        frequency: ReportScheduleFrequency.daily,
        hour: 8,
        minute: 0,
        format: ReportExportFormat.pdf,
        recipientUserIds: const <String>['rep-a'],
      );

      expect(result, isA<AppSuccess<ReportSchedule>>());
      final schedule = (result as AppSuccess<ReportSchedule>).value;
      expect(schedule.status, ReportScheduleStatus.active);
      expect(schedule.nextRunAt.isAfter(DateTime.now()), isTrue);
      verify(() => repository.create(any())).called(1);
    });

    test('SALES_REP cannot create a schedule (PermissionFailure)', () async {
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
        savedReport: buildSavedReport(ownerId: 'rep-a'),
        frequency: ReportScheduleFrequency.daily,
        hour: 8,
        minute: 0,
        format: ReportExportFormat.pdf,
        recipientUserIds: const <String>['rep-a'],
      );

      expect(result, isA<AppFailure<ReportSchedule>>());
      expect(
        (result as AppFailure<ReportSchedule>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(() => repository.create(any()));
    });

    test('rejects an empty recipient list (ValidationFailure)', () async {
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

      final result = await useCase(
        requesterId: 'manager-a',
        savedReport: buildSavedReport(),
        frequency: ReportScheduleFrequency.daily,
        hour: 8,
        minute: 0,
        format: ReportExportFormat.pdf,
        recipientUserIds: const <String>[],
      );

      expect(result, isA<AppFailure<ReportSchedule>>());
      expect(
        (result as AppFailure<ReportSchedule>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.create(any()));
    });

    test(
      'rejects a recipient who is not an active member (ValidationFailure)',
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
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'ghost',
          ),
        ).thenAnswer(
          (_) async => const AppFailure<Membership>(
            NotFoundFailure('not found', code: 'membership_not_found'),
          ),
        );

        final result = await useCase(
          requesterId: 'manager-a',
          savedReport: buildSavedReport(),
          frequency: ReportScheduleFrequency.daily,
          hour: 8,
          minute: 0,
          format: ReportExportFormat.pdf,
          recipientUserIds: const <String>['ghost'],
        );

        expect(result, isA<AppFailure<ReportSchedule>>());
        expect(
          (result as AppFailure<ReportSchedule>).failure,
          isA<ValidationFailure>(),
        );
        verifyNever(() => repository.create(any()));
      },
    );

    test('requires a valid weekday for a weekly schedule', () async {
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

      final result = await useCase(
        requesterId: 'manager-a',
        savedReport: buildSavedReport(),
        frequency: ReportScheduleFrequency.weekly,
        hour: 8,
        minute: 0,
        format: ReportExportFormat.pdf,
        recipientUserIds: const <String>['rep-a'],
      );

      expect(result, isA<AppFailure<ReportSchedule>>());
      expect(
        (result as AppFailure<ReportSchedule>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.create(any()));
    });
  });

  group('PauseReportSchedule', () {
    late PauseReportSchedule useCase;

    setUp(() {
      useCase = PauseReportSchedule(repository, membershipRepository);
    });

    test('creator pauses their own schedule', () async {
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
      when(() => repository.update(any())).thenAnswer(
        (invocation) async => AppSuccess<ReportSchedule>(
          invocation.positionalArguments.first as ReportSchedule,
        ),
      );

      final result = await useCase(
        requesterId: 'manager-a',
        schedule: buildSchedule(),
      );

      expect(result, isA<AppSuccess<ReportSchedule>>());
      expect(
        (result as AppSuccess<ReportSchedule>).value.status,
        ReportScheduleStatus.paused,
      );
    });

    test(
      'a member who is neither the creator nor OWNER/ADMIN cannot pause it',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: organizationId,
            userId: 'finance-a',
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<Membership>(buildMembership('finance-a', 'FINANCE')),
        );

        final result = await useCase(
          requesterId: 'finance-a',
          schedule: buildSchedule(),
        );

        expect(result, isA<AppFailure<ReportSchedule>>());
        expect(
          (result as AppFailure<ReportSchedule>).failure,
          isA<PermissionFailure>(),
        );
        verifyNever(() => repository.update(any()));
      },
    );

    test('ADMIN pauses a schedule created by someone else', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: organizationId,
          userId: 'admin-a',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('admin-a', 'ADMIN')),
      );
      when(() => repository.update(any())).thenAnswer(
        (invocation) async => AppSuccess<ReportSchedule>(
          invocation.positionalArguments.first as ReportSchedule,
        ),
      );

      final result = await useCase(
        requesterId: 'admin-a',
        schedule: buildSchedule(),
      );

      expect(result, isA<AppSuccess<ReportSchedule>>());
    });
  });

  group('DeleteReportSchedule', () {
    late DeleteReportSchedule useCase;

    setUp(() {
      useCase = DeleteReportSchedule(repository, membershipRepository);
    });

    test('creator deletes their own schedule', () async {
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
        () => repository.delete(
          organizationId: organizationId,
          scheduleId: 'schedule-1',
        ),
      ).thenAnswer((_) async => const AppSuccess<void>(null));

      final result = await useCase(
        requesterId: 'manager-a',
        schedule: buildSchedule(),
      );

      expect(result, isA<AppSuccess<void>>());
    });

    test(
      'a member who is neither the creator nor OWNER/ADMIN cannot delete it',
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

        final result = await useCase(
          requesterId: 'rep-a',
          schedule: buildSchedule(),
        );

        expect(result, isA<AppFailure<void>>());
        expect((result as AppFailure<void>).failure, isA<PermissionFailure>());
        verifyNever(
          () => repository.delete(
            organizationId: any(named: 'organizationId'),
            scheduleId: any(named: 'scheduleId'),
          ),
        );
      },
    );
  });

  group('ListReportSchedules', () {
    late ListReportSchedules useCase;

    setUp(() {
      useCase = ListReportSchedules(repository, permissionService);
    });

    test(
      'SALES_MANAGER (report.schedule) lists organization schedules',
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
          () => repository.listByOrganization(
            organizationId: organizationId,
            companyId: companyId,
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<ReportSchedule>>(<ReportSchedule>[
            buildSchedule(),
          ]),
        );

        final result = await useCase(
          organizationId: organizationId,
          companyId: companyId,
          requesterId: 'manager-a',
        );

        expect(result, isA<AppSuccess<List<ReportSchedule>>>());
        expect(
          (result as AppSuccess<List<ReportSchedule>>).value,
          hasLength(1),
        );
      },
    );

    test('SALES_REP cannot list schedules (PermissionFailure)', () async {
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
        requesterId: 'rep-a',
      );

      expect(result, isA<AppFailure<List<ReportSchedule>>>());
      expect(
        (result as AppFailure<List<ReportSchedule>>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(
        () => repository.listByOrganization(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
        ),
      );
    });
  });
}
