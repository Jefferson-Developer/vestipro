import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/barcode_scanner/barcode_scanner.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

final class _FakeProductCodeLookupRepository
    implements ProductCodeLookupRepository {
  int registerCallCount = 0;
  String? lastCode;
  String? lastProductId;
  String? lastVariantId;

  @override
  Future<AppResult<ProductCodeResolution>> resolveCode({
    required String organizationId,
    required String rawCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<AlternateProductCode>> registerAlternateCode({
    required String organizationId,
    required String code,
    required String productId,
    String? variantId,
    required String registeredBy,
  }) async {
    registerCallCount += 1;
    lastCode = code;
    lastProductId = productId;
    lastVariantId = variantId;
    return AppSuccess<AlternateProductCode>(
      AlternateProductCode(
        organizationId: organizationId,
        code: code,
        productId: productId,
        variantId: variantId,
        registeredAt: DateTime.utc(2026, 1, 1),
        registeredBy: registeredBy,
      ),
    );
  }
}

final class _InMemoryAuditLogRepository implements AuditLogRepository {
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
  }) async {
    return AppSuccess<List<AuditLogEntry>>(entries);
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
  }) async {
    return const AppSuccess<AuditLogEntryPage>(
      AuditLogEntryPage(entries: <AuditLogEntry>[], hasMore: false),
    );
  }
}

void main() {
  group('RegisterUnknownProductCodeUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late _FakeProductCodeLookupRepository repository;
    late _InMemoryAuditLogRepository auditLogRepository;
    late FakeAnalyticsService analytics;
    late RegisterUnknownProductCodeUseCase useCase;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      repository = _FakeProductCodeLookupRepository();
      auditLogRepository = _InMemoryAuditLogRepository();
      analytics = FakeAnalyticsService();
      useCase = RegisterUnknownProductCodeUseCase(
        repository,
        permissionService,
        auditLogRepository,
        analytics,
      );
    });

    Membership buildMembership(String roleName, {String userId = 'user-1'}) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: userId,
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: userId,
      );
    }

    test(
      'registers, records an audit entry and logs analytics for an authorized profile',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'user-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('OWNER')),
        );

        final result = await useCase(
          organizationId: 'org-1',
          code: '7891234567895',
          productId: 'product-1',
          variantId: 'variant-1',
          registeredBy: 'user-1',
          actorName: 'Ana Souza',
        );

        expect(result, isA<AppSuccess<AlternateProductCode>>());
        expect(repository.registerCallCount, 1);
        expect(repository.lastProductId, 'product-1');
        expect(repository.lastVariantId, 'variant-1');
        expect(auditLogRepository.entries, hasLength(1));
        expect(
          auditLogRepository.entries.single.action,
          AuditAction.productAlternateCodeRegistered,
        );
        expect(
          analytics.loggedEvents.single.name,
          AnalyticsEvents.barcodeAlternateCodeRegistered,
        );
      },
    );

    test(
      'denies and never calls the repository for a profile without catalogManage',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'seller-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership('SALES_REP', userId: 'seller-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          code: '7891234567895',
          productId: 'product-1',
          registeredBy: 'seller-1',
          actorName: 'Vendedor',
        );

        expect(result, isA<AppFailure<AlternateProductCode>>());
        expect(
          (result as AppFailure<AlternateProductCode>).failure.code,
          'alternate_product_code_register_denied',
        );
        expect(repository.registerCallCount, 0);
        expect(auditLogRepository.entries, isEmpty);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'fails validation without checking permission for a blank code',
      () async {
        final result = await useCase(
          organizationId: 'org-1',
          code: '   ',
          productId: 'product-1',
          registeredBy: 'user-1',
          actorName: 'Ana Souza',
        );

        expect(result, isA<AppFailure<AlternateProductCode>>());
        expect(
          (result as AppFailure<AlternateProductCode>).failure.code,
          'invalid_alternate_product_code_payload',
        );
        expect(repository.registerCallCount, 0);
        verifyNever(
          () => membershipRepository.getByUser(
            organizationId: any(named: 'organizationId'),
            userId: any(named: 'userId'),
          ),
        );
      },
    );
  });
}
