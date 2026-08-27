import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/pricing/pricing.dart';
import 'package:vestipro/features/pricing/presentation/cubit/payment_terms_cubit.dart';
import 'package:vestipro/features/pricing/presentation/pages/payment_terms_page.dart';
import 'package:vestipro/features/pricing/presentation/widgets/payment_term_selector.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  late _MockMembershipRepository membershipRepository;
  late PermissionService permissionService;
  late _InMemoryPaymentTermRepository repository;

  setUp(() {
    membershipRepository = _MockMembershipRepository();
    permissionService = PermissionService(membershipRepository);
    repository = _InMemoryPaymentTermRepository();
    when(
      () => membershipRepository.getByUser(
        organizationId: 'org-1',
        userId: 'user-1',
      ),
    ).thenAnswer(
      (_) async => AppSuccess<Membership>(
        Membership(
          id: 'user-1',
          organizationId: 'org-1',
          userId: 'user-1',
          roleId: 'FINANCE',
          roleName: 'FINANCE',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ),
    );
  });

  Widget buildPage() {
    return PaymentTermsPage(
      organizationId: 'org-1',
      companyId: 'company-1',
      userId: 'user-1',
      actorName: 'Ana',
      permissionService: permissionService,
      createCubit: () => PaymentTermsCubit(
        repository,
        CreatePaymentTermUseCase(repository, _NoopAuditLogRepository()),
        UpdatePaymentTermUseCase(repository, _NoopAuditLogRepository()),
      ),
    );
  }

  testWidgets('validates percentage total in real time', (tester) async {
    await pumpApp(tester, buildPage());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.descendant(
        of: find.bySemanticsLabel('Parcelas da condição de pagamento'),
        matching: find.byType(EditableText),
      ),
      '40:30\n50:60',
    );
    await tester.pumpAndSettle();

    expect(find.text('Total dos percentuais: 90%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('payment_term_total_error')),
      findsOneWidget,
    );
  });

  testWidgets('selector shows only active compatible payment terms', (
    tester,
  ) async {
    final terms = <PaymentTerm>[
      _term('a', '30 dias', priceListIds: const <String>['vip']),
      _term('b', 'Livre'),
      _term('c', 'Inativa', status: PaymentTermStatus.inactive),
      _term('d', 'Outra', priceListIds: const <String>['other']),
    ];

    await pumpApp(
      tester,
      Material(
        child: PaymentTermSelector(
          paymentTerms: terms,
          selectedPaymentTermId: null,
          priceListId: 'vip',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('Selecione uma condição'));
    await tester.pumpAndSettle();

    expect(find.textContaining('30 dias'), findsOneWidget);
    expect(find.textContaining('Livre'), findsOneWidget);
    expect(find.textContaining('Inativa'), findsNothing);
    expect(find.textContaining('Outra'), findsNothing);
  });
}

PaymentTerm _term(
  String id,
  String name, {
  PaymentTermStatus status = PaymentTermStatus.active,
  List<String> priceListIds = const <String>[],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: name,
    installments: const <PaymentInstallment>[
      PaymentInstallment(percentage: 100, dueInDays: 30),
    ],
    averageTermDays: 30,
    status: status,
    priceListIds: priceListIds,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

final class _InMemoryPaymentTermRepository implements PaymentTermRepository {
  final List<PaymentTerm> _terms = <PaymentTerm>[];

  @override
  Future<AppResult<PaymentTerm>> create({
    required PaymentTerm paymentTerm,
  }) async {
    _terms.add(paymentTerm);
    return AppSuccess<PaymentTerm>(paymentTerm);
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) async {
    PaymentTerm? match;
    for (final term in _terms) {
      if (term.id == id) {
        match = term;
        break;
      }
    }
    return AppSuccess<PaymentTerm?>(match);
  }

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PaymentTerm>>(_terms);
  }

  @override
  Future<AppResult<PaymentTerm>> update({
    required PaymentTerm paymentTerm,
  }) async {
    final index = _terms.indexWhere((term) => term.id == paymentTerm.id);
    if (index >= 0) {
      _terms[index] = paymentTerm;
    }
    return AppSuccess<PaymentTerm>(paymentTerm);
  }
}

final class _NoopAuditLogRepository implements AuditLogRepository {
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
    return AppSuccess<AuditLogEntry>(entry);
  }
}
