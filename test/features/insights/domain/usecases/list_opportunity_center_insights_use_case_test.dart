import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/insights/insights.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockInsightRepository extends Mock implements InsightRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('ListOpportunityCenterInsightsUseCase', () {
    late _MockInsightRepository repository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late ListOpportunityCenterInsightsUseCase useCase;

    setUpAll(() {
      registerFallbackValue(
        const InsightVisibilityFilter(
          organizationId: 'org-1',
          userId: 'user-1',
          mode: InsightVisibilityMode.ownOnly,
        ),
      );
    });

    setUp(() {
      repository = _MockInsightRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      useCase = ListOpportunityCenterInsightsUseCase(
        InsightVisibilityService(
          PortfolioVisibilityService(membershipRepository, teamRepository),
          teamRepository,
        ),
        repository,
      );
    });

    Membership buildMembership(String roleName) {
      return Membership(
        id: 'user-1',
        organizationId: 'org-1',
        userId: 'user-1',
        roleId: roleName,
        roleName: roleName,
        teamIds: const <String>[],
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );
    }

    test('rejects blank organizationId/companyId/userId', () async {
      final result = await useCase(
        organizationId: ' ',
        companyId: ' ',
        userId: ' ',
      );

      expect(result, isA<AppFailure<InsightPage>>());
      final failure = (result as AppFailure<InsightPage>).failure;
      expect(failure, isA<ValidationFailure>());
    });

    test('returns PermissionFailure when the resolved visibility cannot view '
        'any insight, without ever querying the repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'stranger-1',
        ),
      ).thenAnswer(
        (_) async => const AppFailure<Membership>(
          NotFoundFailure('Membership not found.'),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'stranger-1',
      );

      expect(result, isA<AppFailure<InsightPage>>());
      expect(
        (result as AppFailure<InsightPage>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(
        () => repository.listPageByVisibility(
          organizationId: any(named: 'organizationId'),
          visibility: any(named: 'visibility'),
        ),
      );
    });

    test('delegates to the repository with the resolved visibility scope once '
        'the caller can view at least one insight', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'seller-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
      );
      const page = InsightPage(insights: <Insight>[], hasMore: false);
      when(
        () => repository.listPageByVisibility(
          organizationId: 'org-1',
          visibility: any(named: 'visibility'),
          limit: 25,
          before: null,
          type: null,
        ),
      ).thenAnswer((_) async => const AppSuccess<InsightPage>(page));

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'seller-1',
      );

      expect(result, isA<AppSuccess<InsightPage>>());
      final captured = verify(
        () => repository.listPageByVisibility(
          organizationId: 'org-1',
          visibility: captureAny(named: 'visibility'),
          limit: 25,
          before: null,
          type: null,
        ),
      ).captured;
      final visibility = captured.single as InsightVisibilityFilter;
      expect(visibility.mode, InsightVisibilityMode.ownOnly);
      expect(visibility.recipientUserIds, <String>{'seller-1'});
    });
  });
}
