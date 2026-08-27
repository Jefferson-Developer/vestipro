import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('UpdatePaymentTermUseCase', () {
    late _FakePaymentTermRepository repository;
    late _FakeAuditLogRepository auditLogRepository;
    late UpdatePaymentTermUseCase useCase;

    setUp(() {
      repository = _FakePaymentTermRepository();
      auditLogRepository = _FakeAuditLogRepository();
      useCase = UpdatePaymentTermUseCase(repository, auditLogRepository);
    });

    test('records update audit', () async {
      repository.term = _initialTerm();

      final result = await useCase(
        organizationId: 'org-1',
        id: 'term-1',
        name: '45 dias',
        installments: const <PaymentInstallment>[
          PaymentInstallment(percentage: 100, dueInDays: 45),
        ],
        updatedBy: 'user-2',
        actorName: 'Ana',
        status: PaymentTermStatus.active,
      );

      expect(result, isA<AppSuccess<PaymentTerm>>());
      expect(
        auditLogRepository.entries.single.action,
        AuditAction.paymentTermUpdated,
      );
    });

    test('records deactivation audit', () async {
      repository.term = _initialTerm();

      final result = await useCase(
        organizationId: 'org-1',
        id: 'term-1',
        name: '30 dias',
        installments: const <PaymentInstallment>[
          PaymentInstallment(percentage: 100, dueInDays: 30),
        ],
        updatedBy: 'user-2',
        actorName: 'Ana',
        status: PaymentTermStatus.inactive,
      );

      expect(result, isA<AppSuccess<PaymentTerm>>());
      expect(
        auditLogRepository.entries.single.action,
        AuditAction.paymentTermDeactivated,
      );
    });
  });
}

PaymentTerm _initialTerm() {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: 'term-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    name: '30 dias',
    installments: const <PaymentInstallment>[
      PaymentInstallment(percentage: 100, dueInDays: 30),
    ],
    averageTermDays: 30,
    status: PaymentTermStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

final class _FakePaymentTermRepository implements PaymentTermRepository {
  PaymentTerm? term;

  @override
  Future<AppResult<PaymentTerm>> create({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) async {
    return AppSuccess<PaymentTerm?>(term);
  }

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm>> update({
    required PaymentTerm paymentTerm,
  }) async {
    term = paymentTerm;
    return AppSuccess<PaymentTerm>(paymentTerm);
  }
}

final class _FakeAuditLogRepository implements AuditLogRepository {
  final List<AuditLogEntry> entries = <AuditLogEntry>[];

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

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    entries.add(entry);
    return AppSuccess<AuditLogEntry>(entry);
  }
}
