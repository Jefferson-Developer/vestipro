import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/after_sales/after_sales.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakePostSaleEventRepository implements PostSaleEventRepository {
  int registerCallCount = 0;
  PostSaleEventType? lastType;
  String? lastDescription;

  @override
  Future<AppResult<PostSaleEventSubmissionResult>> registerPostSaleEvent({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String eventId,
    required PostSaleEventType type,
    String? description,
  }) async {
    registerCallCount += 1;
    lastType = type;
    lastDescription = description;
    return AppSuccess<PostSaleEventSubmissionResult>(
      PostSaleEventSubmissionResult(
        eventId: eventId,
        orderId: orderId,
        type: type,
        description: description,
        createdAt: DateTime.utc(2026, 6, 1),
      ),
    );
  }

  @override
  Stream<AppResult<List<PostSaleEvent>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) => throw UnimplementedError();
}

Widget _buildApp(RegisterPostSaleEventCubit Function() createCubit) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('pt'),
    home: RegisterPostSaleEventPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: 'rep-1',
      orderId: 'order-1',
      orderLabel: '000001',
      createCubit: createCubit,
    ),
  );
}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _FakePostSaleEventRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _FakePostSaleEventRepository();
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'rep-1',
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: 'rep-1',
          organizationId: 'org-1',
          userId: 'rep-1',
          roleId: 'SALES_REP',
          roleName: 'SALES_REP',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'rep-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'rep-1',
        ),
      ),
    );
  });

  RegisterPostSaleEventCubit createCubit() {
    return RegisterPostSaleEventCubit(
      RegisterPostSaleEventUseCase(repository, permissionService),
      FakeAnalyticsService(),
    );
  }

  testWidgets(
    'rejects submission of "problema reportado" without a description, '
    'never calling the repository',
    (tester) async {
      await tester.pumpWidget(_buildApp(createCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppDropdown<PostSaleEventType>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Problema reportado').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar evento'));
      await tester.pumpAndSettle();

      expect(find.text('Descreva o problema reportado.'), findsOneWidget);
      expect(repository.registerCallCount, 0);
    },
  );

  testWidgets(
    'submits a manual milestone that does not require a description',
    (tester) async {
      await tester.pumpWidget(_buildApp(createCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Registrar evento'));
      await tester.pumpAndSettle();

      expect(repository.registerCallCount, 1);
      expect(repository.lastType, PostSaleEventType.dispatched);
    },
  );
}
