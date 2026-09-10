import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/exchanges/exchanges.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeExchangeRequestRepository implements ExchangeRequestRepository {
  _FakeExchangeRequestRepository(this._createResult);

  final AppResult<ExchangeRequestSubmissionResult> _createResult;
  int createCallCount = 0;
  List<ExchangeRequestItemInput>? lastItems;

  @override
  Future<AppResult<ExchangeRequestSubmissionResult>> createExchangeRequest({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String exchangeRequestId,
    required List<ExchangeRequestItemInput> items,
    required ExchangeReasonCategory reasonCategory,
    String? reasonDetails,
  }) async {
    createCallCount += 1;
    lastItems = items;
    return _createResult;
  }

  @override
  Future<AppResult<ExchangeRequestDecisionResult>> resolveExchangeRequest({
    required String organizationId,
    required String companyId,
    required String exchangeRequestId,
    required ExchangeRequestDecisionValue decision,
    String? reason,
  }) {
    throw UnimplementedError();
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
  group('CreateExchangeRequestUseCase', () {
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

    ExchangeRequestSubmissionResult buildResult() {
      return ExchangeRequestSubmissionResult(
        exchangeRequestId: 'exchange-1',
        orderId: 'order-1',
        reasonCategory: ExchangeReasonCategory.sizeIssue,
        requestedAt: DateTime.utc(2026, 6, 1, 12),
      );
    }

    const validItems = [
      ExchangeRequestItemInput(
        orderItemId: 'item-1',
        destinationVariantId: 'variant-destination',
        quantity: 2,
      ),
    ];

    test('opens a troca through the repository when SALES_REP has '
        'exchange.create', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );
      final repository = _FakeExchangeRequestRepository(
        AppSuccess<ExchangeRequestSubmissionResult>(buildResult()),
      );
      final useCase = CreateExchangeRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
        exchangeRequestId: 'exchange-1',
        items: validItems,
        reasonCategory: ExchangeReasonCategory.sizeIssue,
      );

      expect(result, isA<AppSuccess<ExchangeRequestSubmissionResult>>());
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
        final repository = _FakeExchangeRequestRepository(
          AppSuccess<ExchangeRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateExchangeRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          exchangeRequestId: 'exchange-1',
          items: const <ExchangeRequestItemInput>[],
          reasonCategory: ExchangeReasonCategory.sizeIssue,
        );

        expect(result, isA<AppFailure<ExchangeRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ExchangeRequestSubmissionResult>).failure.code,
          'exchange_request_items_required',
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
        final repository = _FakeExchangeRequestRepository(
          AppSuccess<ExchangeRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateExchangeRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          exchangeRequestId: 'exchange-1',
          items: const [
            ExchangeRequestItemInput(
              orderItemId: 'item-1',
              destinationVariantId: 'variant-destination',
              quantity: 0,
            ),
          ],
          reasonCategory: ExchangeReasonCategory.sizeIssue,
        );

        expect(result, isA<AppFailure<ExchangeRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ExchangeRequestSubmissionResult>).failure.code,
          'exchange_request_invalid_quantity',
        );
        expect(repository.createCallCount, 0);
      },
    );

    test(
      'fails without calling the repository when a destination variant is missing',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );
        final repository = _FakeExchangeRequestRepository(
          AppSuccess<ExchangeRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateExchangeRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          orderId: 'order-1',
          exchangeRequestId: 'exchange-1',
          items: const [
            ExchangeRequestItemInput(
              orderItemId: 'item-1',
              destinationVariantId: '',
              quantity: 2,
            ),
          ],
          reasonCategory: ExchangeReasonCategory.sizeIssue,
        );

        expect(result, isA<AppFailure<ExchangeRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ExchangeRequestSubmissionResult>).failure.code,
          'exchange_request_destination_required',
        );
        expect(repository.createCallCount, 0);
      },
    );

    test(
      'fails without calling the repository when the caller lacks exchange.create',
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
        final repository = _FakeExchangeRequestRepository(
          AppSuccess<ExchangeRequestSubmissionResult>(buildResult()),
        );
        final useCase = CreateExchangeRequestUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'assistant-1',
          orderId: 'order-1',
          exchangeRequestId: 'exchange-1',
          items: validItems,
          reasonCategory: ExchangeReasonCategory.sizeIssue,
        );

        expect(result, isA<AppFailure<ExchangeRequestSubmissionResult>>());
        expect(
          (result as AppFailure<ExchangeRequestSubmissionResult>).failure.code,
          'exchange_request_create_denied',
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
      final repository = _FakeExchangeRequestRepository(
        const AppFailure<ExchangeRequestSubmissionResult>(
          ValidationFailure(
            'A variante de destino não tem estoque suficiente.',
            code: 'failed-precondition',
          ),
        ),
      );
      final useCase = CreateExchangeRequestUseCase(
        repository,
        permissionService,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        orderId: 'order-1',
        exchangeRequestId: 'exchange-1',
        items: validItems,
        reasonCategory: ExchangeReasonCategory.sizeIssue,
      );

      expect(result, isA<AppFailure<ExchangeRequestSubmissionResult>>());
      expect(repository.createCallCount, 1);
    });
  });
}
