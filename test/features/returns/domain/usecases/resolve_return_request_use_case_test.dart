import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/returns/returns.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeReturnRequestRepository implements ReturnRequestRepository {
  _FakeReturnRequestRepository(this._resolveResult);

  final AppResult<ReturnRequestDecisionResult> _resolveResult;
  int resolveCallCount = 0;
  ReturnRequestDecisionValue? lastDecision;
  String? lastReason;

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
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<ReturnRequestDecisionResult>> resolveReturnRequest({
    required String organizationId,
    required String companyId,
    required String returnRequestId,
    required ReturnRequestDecisionValue decision,
    String? reason,
  }) async {
    resolveCallCount += 1;
    lastDecision = decision;
    lastReason = reason;
    return _resolveResult;
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
  group('ResolveReturnRequestUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'manager-1',
        organizationId: 'org-1',
        userId: 'manager-1',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'manager-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'manager-1',
      );
    }

    ReturnRequestDecisionResult buildResult({
      required ReturnRequestStatus status,
      String? reason,
    }) {
      return ReturnRequestDecisionResult(
        returnRequestId: 'return-1',
        orderId: 'order-1',
        status: status,
        decidedBy: 'manager-1',
        decidedAt: DateTime.utc(2026, 6, 1, 12),
        reason: reason,
      );
    }

    test('approves through the repository when SALES_MANAGER has '
        'return.approve', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );
      final repository = _FakeReturnRequestRepository(
        AppSuccess<ReturnRequestDecisionResult>(
          buildResult(status: ReturnRequestStatus.approved),
        ),
      );
      final useCase = ResolveReturnRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        returnRequestId: 'return-1',
        decision: ReturnRequestDecisionValue.approved,
      );

      expect(result, isA<AppSuccess<ReturnRequestDecisionResult>>());
      expect(repository.resolveCallCount, 1);
      expect(repository.lastDecision, ReturnRequestDecisionValue.approved);
    });

    test(
      'fails without calling the repository when rejecting without a reason',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeReturnRequestRepository(
          AppSuccess<ReturnRequestDecisionResult>(
            buildResult(status: ReturnRequestStatus.rejected),
          ),
        );
        final useCase = ResolveReturnRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'manager-1',
          returnRequestId: 'return-1',
          decision: ReturnRequestDecisionValue.rejected,
        );

        expect(result, isA<AppFailure<ReturnRequestDecisionResult>>());
        expect(
          (result as AppFailure<ReturnRequestDecisionResult>).failure.code,
          'return_request_rejection_reason_required',
        );
        expect(repository.resolveCallCount, 0);
      },
    );

    test('fails without calling the repository when the caller lacks '
        'return.approve', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership('SALES_REP').copyWith(id: 'rep-1', userId: 'rep-1'),
        ),
      );
      final repository = _FakeReturnRequestRepository(
        AppSuccess<ReturnRequestDecisionResult>(
          buildResult(status: ReturnRequestStatus.approved),
        ),
      );
      final useCase = ResolveReturnRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        returnRequestId: 'return-1',
        decision: ReturnRequestDecisionValue.approved,
      );

      expect(result, isA<AppFailure<ReturnRequestDecisionResult>>());
      expect(
        (result as AppFailure<ReturnRequestDecisionResult>).failure.code,
        'return_request_approve_denied',
      );
      expect(repository.resolveCallCount, 0);
    });

    test('rejects with a reason through the repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );
      final repository = _FakeReturnRequestRepository(
        AppSuccess<ReturnRequestDecisionResult>(
          buildResult(
            status: ReturnRequestStatus.rejected,
            reason: 'Fora do prazo de troca.',
          ),
        ),
      );
      final useCase = ResolveReturnRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        returnRequestId: 'return-1',
        decision: ReturnRequestDecisionValue.rejected,
        reason: 'Fora do prazo de troca.',
      );

      expect(result, isA<AppSuccess<ReturnRequestDecisionResult>>());
      expect(repository.lastReason, 'Fora do prazo de troca.');
    });

    test('propagates a server-side decision failure', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );
      final repository = _FakeReturnRequestRepository(
        const AppFailure<ReturnRequestDecisionResult>(
          ValidationFailure(
            'Esta devolução já foi decidida.',
            code: 'failed-precondition',
          ),
        ),
      );
      final useCase = ResolveReturnRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        returnRequestId: 'return-1',
        decision: ReturnRequestDecisionValue.approved,
      );

      expect(result, isA<AppFailure<ReturnRequestDecisionResult>>());
    });
  });
}
