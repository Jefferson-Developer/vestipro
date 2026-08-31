import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/permissions/permission_service.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('PaymentTermOfflinePackageEntityLoader', () {
    late _FakePaymentTermRepository paymentTermRepository;
    late _FakePaymentTermLocalStoreRepository localStore;
    late _FakeMembershipRepository membershipRepository;
    late PaymentTermOfflinePackageEntityLoader loader;

    setUp(() {
      paymentTermRepository = _FakePaymentTermRepository();
      localStore = _FakePaymentTermLocalStoreRepository();
      membershipRepository = _FakeMembershipRepository();
      loader = PaymentTermOfflinePackageEntityLoader(
        LoadInitialPaymentTermOfflineDataUseCase(
          paymentTermRepository,
          localStore,
        ),
        localStore,
        PermissionService(membershipRepository),
      );
    });

    test('kind is paymentTerms', () {
      expect(loader.kind, OfflinePackageEntityKind.paymentTerms);
    });

    test('is applicable for a SALES_MANAGER (has orderCreate)', () async {
      membershipRepository.membership = _membership(roleName: 'SALES_MANAGER');

      final result = await loader.isApplicable(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect((result as AppSuccess<bool>).value, isTrue);
    });

    test('is not applicable when there is no active Membership', () async {
      final result = await loader.isApplicable(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isFalse);
    });

    test('load replaces the local cache and reports progress once', () async {
      paymentTermRepository.paymentTerms.add(_paymentTerm('a'));
      final reported = <int>[];

      final result = await loader.load(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'user-1',
        cancellationToken: OfflinePackageCancellationToken(),
        onProgress: reported.add,
      );

      final entityResult =
          (result as AppSuccess<OfflinePackageEntityLoadResult>).value;
      expect(entityResult.outcome, OfflinePackageEntityLoadOutcome.completed);
      expect(entityResult.recordCount, 1);
      expect(reported, <int>[1]);
    });

    test(
      'load never touches the remote/local store once already cancelled',
      () async {
        paymentTermRepository.paymentTerms.add(_paymentTerm('a'));
        final token = OfflinePackageCancellationToken()..cancel();

        final result = await loader.load(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'user-1',
          cancellationToken: token,
          onProgress: (_) {},
        );

        final entityResult =
            (result as AppSuccess<OfflinePackageEntityLoadResult>).value;
        expect(entityResult.outcome, OfflinePackageEntityLoadOutcome.cancelled);
        expect(localStore.replaceCalls, isEmpty);
      },
    );
  });
}

PaymentTerm _paymentTerm(String id) {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'Condição $id',
    installments: const <PaymentInstallment>[],
    averageTermDays: 30,
    status: PaymentTermStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

Membership _membership({required String roleName}) {
  final now = DateTime.utc(2026, 1, 1);
  return Membership(
    id: 'membership-1',
    organizationId: 'org-1',
    userId: 'user-1',
    roleId: 'role-1',
    roleName: roleName,
    status: MembershipStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

final class _FakePaymentTermRepository implements PaymentTermRepository {
  final List<PaymentTerm> paymentTerms = <PaymentTerm>[];

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PaymentTerm>>(List<PaymentTerm>.of(paymentTerms));
  }

  @override
  Future<AppResult<PaymentTerm>> create({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm>> update({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePaymentTermLocalStoreRepository
    implements PaymentTermLocalStoreRepository {
  final List<List<PaymentTerm>> replaceCalls = <List<PaymentTerm>>[];

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PaymentTerm> paymentTerms,
  }) async {
    replaceCalls.add(paymentTerms);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> upsert({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PaymentTerm>>> getAll({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<int>(0);
  }
}

final class _FakeMembershipRepository implements MembershipRepository {
  Membership? membership;

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    final current = membership;
    if (current == null) {
      return const AppFailure<Membership>(NotFoundFailure('not found'));
    }
    return AppSuccess<Membership>(current);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) {
    throw UnimplementedError();
  }
}
