import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/navigation/navigation.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/opportunities/opportunities.dart';
import 'package:vestipro/features/organizations/organizations.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('OpportunityOutcomeReasonAdminPage', () {
    late _MockMembershipRepository membershipRepository;
    late _InMemoryOutcomeReasonRepository reasonRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      reasonRepository = _InMemoryOutcomeReasonRepository();
      permissionService = PermissionService(membershipRepository);
      _stubMembership(membershipRepository, roleName: 'SALES_MANAGER');
    });

    OpportunityOutcomeReasonAdminBloc buildBloc() {
      return OpportunityOutcomeReasonAdminBloc(
        listReasons: ListOpportunityOutcomeReasonsUseCase(reasonRepository),
        createReason: CreateOpportunityOutcomeReasonUseCase(reasonRepository),
        updateReason: UpdateOpportunityOutcomeReasonUseCase(reasonRepository),
        deactivateReason: DeactivateOpportunityOutcomeReasonUseCase(
          reasonRepository,
        ),
      );
    }

    Widget buildPage() {
      return OpportunityOutcomeReasonAdminPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildBloc,
      );
    }

    testWidgets('renders forbidden for a role without management permission', (
      tester,
    ) async {
      _stubMembership(membershipRepository, roleName: 'SALES_REP');

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(ForbiddenPage), findsOneWidget);
    });

    testWidgets('creates and deactivates an outcome reason', (tester) async {
      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Novo motivo'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(AppTextField),
        'Produto aderente a colecao',
      );
      await tester.tap(find.widgetWithText(AppButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Produto aderente a colecao'), findsOneWidget);
      expect(reasonRepository.reasons.single.isActive, isTrue);

      await tester.tap(find.widgetWithText(AppButton, 'Desativar'));
      await tester.pumpAndSettle();

      expect(reasonRepository.reasons.single.isActive, isFalse);
      expect(find.text('Inativo'), findsOneWidget);
    });
  });
}

void _stubMembership(
  _MockMembershipRepository repository, {
  required String roleName,
}) {
  when(
    () => repository.getByUser(organizationId: 'org-1', userId: 'current-user'),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

final class _InMemoryOutcomeReasonRepository
    implements OpportunityOutcomeReasonRepository {
  final List<OpportunityOutcomeReason> reasons = <OpportunityOutcomeReason>[];

  @override
  Future<AppResult<OpportunityOutcomeReason>> create({
    required OpportunityOutcomeReason reason,
  }) async {
    reasons.add(reason);
    return AppSuccess<OpportunityOutcomeReason>(reason);
  }

  @override
  Future<AppResult<OpportunityOutcomeReason>> update({
    required OpportunityOutcomeReason reason,
  }) async {
    final index = reasons.indexWhere((existing) => existing.id == reason.id);
    if (index == -1) {
      return const AppFailure<OpportunityOutcomeReason>(
        NotFoundFailure(
          'Opportunity outcome reason not found.',
          code: 'opportunity_outcome_reason_not_found',
        ),
      );
    }
    reasons[index] = reason;
    return AppSuccess<OpportunityOutcomeReason>(reason);
  }

  @override
  Future<AppResult<OpportunityOutcomeReason>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final reason in reasons) {
      if (reason.organizationId == organizationId && reason.id == id) {
        return AppSuccess<OpportunityOutcomeReason>(reason);
      }
    }
    return const AppFailure<OpportunityOutcomeReason>(
      NotFoundFailure(
        'Opportunity outcome reason not found.',
        code: 'opportunity_outcome_reason_not_found',
      ),
    );
  }

  @override
  Future<AppResult<List<OpportunityOutcomeReason>>> listByOrganization({
    required String organizationId,
    OpportunityOutcomeType? type,
    bool includeInactive = false,
  }) async {
    final visible = reasons
        .where(
          (reason) =>
              reason.organizationId == organizationId &&
              (type == null || reason.type == type) &&
              (includeInactive || reason.isActive),
        )
        .toList(growable: false);
    return AppSuccess<List<OpportunityOutcomeReason>>(visible);
  }
}
