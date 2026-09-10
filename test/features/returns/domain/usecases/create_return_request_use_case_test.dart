import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/returns/returns.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeReturnRequestRepository implements ReturnRequestRepository {
  _FakeReturnRequestRepository(this._createResult);

  final AppResult<ReturnRequestSubmissionResult> _createResult;
  int createCallCount = 0;
  List<ReturnRequestItemInput>? lastItems;
  String? lastReturnRequestId;

  @override
  Future<AppResult<ReturnRequestSubmissionResult>> createReturnRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String returnRequestId,
    required List<ReturnRequestItemInput> items,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String> evidenceUrls = const <String>[],
  }) async {
    createCallCount += 1;
    lastItems = items;
    lastReturnRequestId = returnRequestId;
    return _createResult;
  }

  @override
  Future<AppResult<ReturnRequestDecisionResult>> resolveReturnRequest({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ReturnRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ReturnRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds = const <String>{},
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('CreateReturnRequestUseCase', () {
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

    ReturnRequestSubmissionResult buildResult() {
      return ReturnRequestSubmissionResult(
        returnRequestId: 'return-1',
        orderId: 'order-1',
        reasonCategory: ReturnReasonCategory.defect,
        refundAmount: 200,
        requestedAt: DateTime.utc(2026, 6, 1, 12),
      );
    }

    test('opens a devolução through the repository when SALES_REP has '
        'return.create', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );
      final repository = _FakeReturnRequestRepository(
        AppSuccess<ReturnRequestSubmissionResult>(buildResult()),
      );
      final useCase = CreateReturnRequestUseCase(repository, permissionService);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
        returnRequestId: 'return-1',
        items: const [
          ReturnRequestItemInput(orderItemId: 'item-1', quantity: 2),
        ],
        reasonCategory: ReturnReasonCategory.defect,
      );

      expect(result, isA<AppSuccess<ReturnRequestSubmissionResult>>());
      expect(repository.createCallCount, 1);
      expect(repository.lastItems, hasLength(1));
    });

    test(
      'fails without calling the repository when no item is selected',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );
        final repository = _FakeReturnRequestRepository(
          AppSuccess<ReturnRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateReturnRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          returnRequestId: 'return-1',
          items: const <ReturnRequestItemInput>[],
          reasonCategory: ReturnReasonCategory.defect,
        );

        expect(result, isA<AppFailure<ReturnRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ReturnRequestSubmissionResult>).failure.code,
          'return_request_items_required',
        );
        expect(repository.createCallCount, 0);
      },
    );

    test(
      'fails without calling the repository when a quantity is zero or negative',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );
        final repository = _FakeReturnRequestRepository(
          AppSuccess<ReturnRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateReturnRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          returnRequestId: 'return-1',
          items: const [
            ReturnRequestItemInput(orderItemId: 'item-1', quantity: 0),
          ],
          reasonCategory: ReturnReasonCategory.defect,
        );

        expect(result, isA<AppFailure<ReturnRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ReturnRequestSubmissionResult>).failure.code,
          'return_request_invalid_quantity',
        );
        expect(repository.createCallCount, 0);
      },
    );

    test(
      'fails without calling the repository when the caller lacks return.create',
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
        final repository = _FakeReturnRequestRepository(
          AppSuccess<ReturnRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateReturnRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'assistant-1',
          orderId: 'order-1',
          returnRequestId: 'return-1',
          items: const [
            ReturnRequestItemInput(orderItemId: 'item-1', quantity: 2),
          ],
          reasonCategory: ReturnReasonCategory.defect,
        );

        expect(result, isA<AppFailure<ReturnRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ReturnRequestSubmissionResult>).failure.code,
          'return_request_create_denied',
        );
        expect(repository.createCallCount, 0);
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
      final repository = _FakeReturnRequestRepository(
        const AppFailure<ReturnRequestSubmissionResult>(
          ValidationFailure(
            'A quantidade solicitada excede a quantidade disponível.',
            code: 'failed-precondition',
          ),
        ),
      );
      final useCase = CreateReturnRequestUseCase(repository, permissionService);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
        returnRequestId: 'return-1',
        items: const [
          ReturnRequestItemInput(orderItemId: 'item-1', quantity: 99),
        ],
        reasonCategory: ReturnReasonCategory.defect,
      );

      expect(result, isA<AppFailure<ReturnRequestSubmissionResult>>());
      expect(repository.createCallCount, 1);
    });
  });
}
