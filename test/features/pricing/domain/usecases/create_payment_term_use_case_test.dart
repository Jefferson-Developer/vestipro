import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('CreatePaymentTermUseCase', () {
    late _FakePaymentTermRepository repository;
    late _FakeAuditLogRepository auditLogRepository;
    late CreatePaymentTermUseCase useCase;

    setUp(() {
      repository = _FakePaymentTermRepository();
      auditLogRepository = _FakeAuditLogRepository();
      useCase = CreatePaymentTermUseCase(repository, auditLogRepository);
    });

    Future<AppResult<PaymentTerm>> call({
      List<PaymentInstallment> installments = const <PaymentInstallment>[
        PaymentInstallment(percentage: 50, dueInDays: 30),
        PaymentInstallment(percentage: 50, dueInDays: 60),
      ],
    }) {
      return useCase(
        id: 'term-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: '30/60',
        installments: installments,
        createdBy: 'user-1',
        actorName: 'Ana',
      );
    }

    test(
      'creates a valid payment term and calculates average term days',
      () async {
        final result = await call();

        expect(result, isA<AppSuccess<PaymentTerm>>());
        final value = (result as AppSuccess<PaymentTerm>).value;
        expect(value.averageTermDays, 45);
        expect(value.status, PaymentTermStatus.active);
        expect(
          auditLogRepository.entries.single.action,
          AuditAction.paymentTermCreated,
        );
      },
    );

    test('rejects percentages that do not sum 100%', () async {
      final result = await call(
        installments: const <PaymentInstallment>[
          PaymentInstallment(percentage: 40, dueInDays: 30),
          PaymentInstallment(percentage: 50, dueInDays: 60),
        ],
      );

      expect(result, isA<AppFailure<PaymentTerm>>());
      final failure =
          (result as AppFailure<PaymentTerm>).failure as ValidationFailure;
      expect(failure.fieldErrors.containsKey('installments'), isTrue);
    });

    test('rejects installment with negative due date', () async {
      final result = await call(
        installments: const <PaymentInstallment>[
          PaymentInstallment(percentage: 100, dueInDays: -1),
        ],
      );

      expect(result, isA<AppFailure<PaymentTerm>>());
    });

    test('rejects condition without installments', () async {
      final result = await call(installments: const <PaymentInstallment>[]);

      expect(result, isA<AppFailure<PaymentTerm>>());
    });
  });
}

final class _FakePaymentTermRepository implements PaymentTermRepository {
  final List<PaymentTerm> terms = <PaymentTerm>[];

  @override
  Future<AppResult<PaymentTerm>> create({
    required PaymentTerm paymentTerm,
  }) async {
    terms.add(paymentTerm);
    return AppSuccess<PaymentTerm>(paymentTerm);
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm>> update({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }
}

final class _FakeAuditLogRepository implements AuditLogRepository {
  final List<AuditLogEntry> entries = <AuditLogEntry>[];

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    entries.add(entry);
    return AppSuccess<AuditLogEntry>(entry);
  }

  @override
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
    String? actorUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<AuditLogEntryPage>> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  }) {
    throw UnimplementedError();
  }
}
