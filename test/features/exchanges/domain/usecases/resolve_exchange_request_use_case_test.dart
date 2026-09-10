import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/exchanges/exchanges.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeExchangeRequestRepository implements ExchangeRequestRepository {
  _FakeExchangeRequestRepository(this._resolveResult);

  final AppResult<ExchangeRequestDecisionResult> _resolveResult;
  int resolveCallCount = 0;
  ExchangeRequestDecisionValue? lastDecision;
  String? lastReason;

  @override
  Future<AppResult<ExchangeRequestSubmissionResult>> createExchangeRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<ExchangeRequestDecisionResult>> resolveExchangeRequest({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) async {
    resolveCallCount += 1;
    lastDecision = decision;
    lastReason = reason;
    return _resolveResult;
  }

  @override
  Stream<AppResult<List<ExchangeRequest>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<AppResult<List<ExchangeRequest>>> watchQueue({
    required String organizationId,
    required String companyId,
    required bool allCompany,
    Set<String> sellerIds = const <String>{},
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('ResolveExchangeRequestUseCase', () {
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

    ExchangeRequestDecisionResult buildResult({
      required ExchangeRequestStatus status,
      String? reason,
      double? priceDifferenceAmount,
    }) {
      return ExchangeRequestDecisionResult(
        exchangeRequestId: 'exchange-1',
        orderId: 'order-1',
        status: status,
        decidedBy: 'manager-1',
        decidedAt: DateTime.utc(2026, 6, 1, 12),
        reason: reason,
        priceDifferenceAmount: priceDifferenceAmount,
      );
    }

    test('approves through the repository when SALES_MANAGER has '
        'exchange.approve', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );
      final repository = _FakeExchangeRequestRepository(
        AppSuccess<ExchangeRequestDecisionResult>(
          buildResult(
            status: ExchangeRequestStatus.approved,
            priceDifferenceAmount: 0,
          ),
        ),
      );
      final useCase = ResolveExchangeRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        exchangeRequestId: 'exchange-1',
        decision: ExchangeRequestDecisionValue.approved,
      );

      expect(result, isA<AppSuccess<ExchangeRequestDecisionResult>>());
      expect(repository.resolveCallCount, 1);
      expect(repository.lastDecision, ExchangeRequestDecisionValue.approved);
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
        final repository = _FakeExchangeRequestRepository(
          AppSuccess<ExchangeRequestDecisionResult>(
            buildResult(status: ExchangeRequestStatus.rejected),
          ),
        );
        final useCase = ResolveExchangeRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'manager-1',
          exchangeRequestId: 'exchange-1',
          decision: ExchangeRequestDecisionValue.rejected,
        );

        expect(result, isA<AppFailure<ExchangeRequestDecisionResult>>());
        expect(
          (result as AppFailure<ExchangeRequestDecisionResult>).failure.code,
          'exchange_request_rejection_reason_required',
        );
        expect(repository.resolveCallCount, 0);
      },
    );

    test('fails without calling the repository when the caller lacks '
        'exchange.approve', () async {
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
      final repository = _FakeExchangeRequestRepository(
        AppSuccess<ExchangeRequestDecisionResult>(
          buildResult(status: ExchangeRequestStatus.approved),
        ),
      );
      final useCase = ResolveExchangeRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        exchangeRequestId: 'exchange-1',
        decision: ExchangeRequestDecisionValue.approved,
      );

      expect(result, isA<AppFailure<ExchangeRequestDecisionResult>>());
      expect(
        (result as AppFailure<ExchangeRequestDecisionResult>).failure.code,
        'exchange_request_approve_denied',
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
      final repository = _FakeExchangeRequestRepository(
        AppSuccess<ExchangeRequestDecisionResult>(
          buildResult(
            status: ExchangeRequestStatus.rejected,
            reason: 'Variante indisponível.',
          ),
        ),
      );
      final useCase = ResolveExchangeRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        exchangeRequestId: 'exchange-1',
        decision: ExchangeRequestDecisionValue.rejected,
        reason: 'Variante indisponível.',
      );

      expect(result, isA<AppSuccess<ExchangeRequestDecisionResult>>());
      expect(repository.lastReason, 'Variante indisponível.');
    });

    test('propagates a server-side decision failure (e.g. destination '
        'variant unavailable at approval time)', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );
      final repository = _FakeExchangeRequestRepository(
        const AppFailure<ExchangeRequestDecisionResult>(
          ValidationFailure(
            'A variante de destino ficou indisponível desde a solicitação.',
            code: 'failed-precondition',
          ),
        ),
      );
      final useCase = ResolveExchangeRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        exchangeRequestId: 'exchange-1',
        decision: ExchangeRequestDecisionValue.approved,
      );

      expect(result, isA<AppFailure<ExchangeRequestDecisionResult>>());
    });
  });
}
