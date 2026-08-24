import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/products/products.dart';

import '../../../../core/design_system/components/test_pump_app.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockCollectionRepository extends Mock implements CollectionRepository {}

class _MockSeasonRepository extends Mock implements SeasonRepository {}

void main() {
  group('CollectionsPage', () {
    late _MockMembershipRepository membershipRepository;
    late _MockCollectionRepository collectionRepository;
    late _MockSeasonRepository seasonRepository;
    late PermissionService permissionService;

    Membership ownerMembership() {
      return Membership(
        id: 'current-user',
        organizationId: 'org-1',
        userId: 'current-user',
        roleId: 'OWNER',
        roleName: 'OWNER',
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
        name: 'Ana Souza',
        email: 'ana@vestipro.com.br',
      );
    }

    Collection collection() {
      final now = DateTime.utc(2026, 1, 1);
      return Collection(
        id: 'collection-1',
        organizationId: 'org-1',
        name: 'Verão 2026',
        status: CollectionStatus.active,
        version: 1,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
      );
    }

    CollectionFormBloc buildFormBloc() {
      return CollectionFormBloc(
        listSeasons: ListSeasonsUseCase(seasonRepository),
        createCollection: CreateCollectionUseCase(collectionRepository),
        updateCollection: UpdateCollectionUseCase(collectionRepository),
      );
    }

    CollectionListBloc buildListBloc() {
      return CollectionListBloc(
        listCollections: ListCollectionsUseCase(collectionRepository),
        closeCollection: CloseCollectionUseCase(collectionRepository),
      );
    }

    Widget buildPage() {
      return CollectionsPage(
        organizationId: 'org-1',
        userId: 'current-user',
        permissionService: permissionService,
        createBloc: buildListBloc,
        createFormBloc: buildFormBloc,
      );
    }

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      collectionRepository = _MockCollectionRepository();
      seasonRepository = _MockSeasonRepository();
      permissionService = PermissionService(membershipRepository);

      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'current-user',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(ownerMembership()));
      when(
        () => seasonRepository.listByOrganization('org-1'),
      ).thenAnswer((_) async => const AppSuccess<List<Season>>(<Season>[]));
    });

    testWidgets('shows an empty state guiding the first collection creation', (
      tester,
    ) async {
      when(() => collectionRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => const AppSuccess<List<Collection>>(<Collection>[]),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma coleção cadastrada'), findsOneWidget);
      expect(find.text('Criar primeira coleção'), findsOneWidget);
    });

    testWidgets('shows an error state when loading collections fails', (
      tester,
    ) async {
      when(() => collectionRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => const AppFailure<List<Collection>>(
          UnexpectedFailure('Falha ao carregar.', code: 'boom'),
        ),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar as coleções'),
        findsOneWidget,
      );
    });

    testWidgets('renders existing collections with year and status', (
      tester,
    ) async {
      when(() => collectionRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Collection>>(<Collection>[collection()]),
      );

      await pumpApp(tester, buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Verão 2026'), findsOneWidget);
      expect(find.text('Ativa'), findsOneWidget);
    });
  });
}
