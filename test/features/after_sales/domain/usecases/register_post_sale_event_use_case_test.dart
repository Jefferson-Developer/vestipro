import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/after_sales/after_sales.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakePostSaleEventRepository implements PostSaleEventRepository {
  _FakePostSaleEventRepository(this._registerResult);

  final AppResult<PostSaleEventSubmissionResult> _registerResult;
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
    return _registerResult;
  }

  @override
  Stream<AppResult<List<PostSaleEvent>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('RegisterPostSaleEventUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'rep-1',
        organizationId: 'org-1',
        userId: 'rep-1',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'rep-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'rep-1',
      );
    }

    PostSaleEventSubmissionResult buildResult({
      PostSaleEventType type = PostSaleEventType.delivered,
      String? description,
    }) {
      return PostSaleEventSubmissionResult(
        eventId: 'event-1',
        orderId: 'order-1',
        type: type,
        description: description,
        createdAt: DateTime.utc(2026, 6, 1, 12),
      );
    }

    test('registers a manual milestone through the repository when '
        'SALES_REP has postSaleEvent.register', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );
      final repository = _FakePostSaleEventRepository(
        AppSuccess<PostSaleEventSubmissionResult>(buildResult()),
      );
      final useCase = RegisterPostSaleEventUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
        eventId: 'event-1',
        type: PostSaleEventType.delivered,
      );

      expect(result, isA<AppSuccess<PostSaleEventSubmissionResult>>());
      expect(repository.registerCallCount, 1);
      expect(repository.lastType, PostSaleEventType.delivered);
    });

    test(
      'fails without calling the repository for a system-only type '
      '(never selectable manually)',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );
        final repository = _FakePostSaleEventRepository(
          AppSuccess<PostSaleEventSubmissionResult>(buildResult()),
        );
        final useCase = RegisterPostSaleEventUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          eventId: 'event-1',
          type: PostSaleEventType.returnRequested,
        );

        expect(result, isA<AppFailure<PostSaleEventSubmissionResult>>());
        expect(
          (result as AppFailure<PostSaleEventSubmissionResult>).failure.code,
          'post_sale_event_type_not_manual',
        );
        expect(repository.registerCallCount, 0);
      },
    );

    test(
      'fails without calling the repository when "problema reportado" has '
      'no description',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );
        final repository = _FakePostSaleEventRepository(
          AppSuccess<PostSaleEventSubmissionResult>(buildResult()),
        );
        final useCase = RegisterPostSaleEventUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          eventId: 'event-1',
          type: PostSaleEventType.problemReported,
          description: '   ',
        );

        expect(result, isA<AppFailure<PostSaleEventSubmissionResult>>());
        expect(
          (result as AppFailure<PostSaleEventSubmissionResult>).failure.code,
          'post_sale_event_description_required',
        );
        expect(repository.registerCallCount, 0);
      },
    );

    test(
      'fails without calling the repository when the caller lacks '
      'postSaleEvent.register',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'assistant-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership(
              'SALES_ASSISTANT',
            ).copyWith(id: 'assistant-1', userId: 'assistant-1'),
          ),
        );
        final repository = _FakePostSaleEventRepository(
          AppSuccess<PostSaleEventSubmissionResult>(buildResult()),
        );
        final useCase = RegisterPostSaleEventUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'assistant-1',
          orderId: 'order-1',
          eventId: 'event-1',
          type: PostSaleEventType.delivered,
        );

        expect(result, isA<AppFailure<PostSaleEventSubmissionResult>>());
        expect(
          (result as AppFailure<PostSaleEventSubmissionResult>).failure.code,
          'post_sale_event_register_denied',
        );
        expect(repository.registerCallCount, 0);
      },
    );

    test('propagates a server-side failure from the repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );
      final repository = _FakePostSaleEventRepository(
        const AppFailure<PostSaleEventSubmissionResult>(
          ValidationFailure(
            'Este pedido não está em um status elegível.',
            code: 'failed-precondition',
          ),
        ),
      );
      final useCase = RegisterPostSaleEventUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
        eventId: 'event-1',
        type: PostSaleEventType.delivered,
      );

      expect(result, isA<AppFailure<PostSaleEventSubmissionResult>>());
      expect(repository.registerCallCount, 1);
    });
  });
}
