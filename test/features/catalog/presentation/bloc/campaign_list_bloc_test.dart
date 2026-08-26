import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/catalog/catalog.dart';

import '../../catalog_test_fakes.dart';

void main() {
  group('CampaignListBloc', () {
    late InMemoryCatalogCampaignRepository repository;

    setUp(() {
      repository = InMemoryCatalogCampaignRepository();
    });

    CampaignListBloc buildBloc() {
      return CampaignListBloc(
        listCampaigns: ListCampaignsUseCase(repository),
        deleteCampaign: DeleteCampaignUseCase(repository),
        now: () => DateTime.utc(2026, 6, 15),
      );
    }

    test('loads every campaign of the organization, active or not', () async {
      repository.seed(buildTestCampaign(id: 'campaign-1'));
      repository.seed(
        buildTestCampaign(id: 'campaign-2').copyWith(active: false),
      );

      final bloc = buildBloc()
        ..add(
          const CampaignListStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();

      expect(bloc.state.loadStatus, CampaignListLoadStatus.ready);
      expect(bloc.state.campaigns, hasLength(2));
      await bloc.close();
    });

    test('filters campaigns by search query', () async {
      repository.seed(
        buildTestCampaign(id: 'campaign-1').copyWith(title: 'Verão'),
      );
      repository.seed(
        buildTestCampaign(id: 'campaign-2').copyWith(title: 'Inverno'),
      );

      final bloc = buildBloc()
        ..add(
          const CampaignListStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();

      bloc.add(const CampaignListSearchChanged('inv'));
      await _drainBloc();

      expect(bloc.state.filteredCampaigns.single.title, 'Inverno');
      await bloc.close();
    });

    test('deletes a campaign and reflects it without a full reload', () async {
      repository.seed(buildTestCampaign(id: 'campaign-1'));

      final bloc = buildBloc()
        ..add(
          const CampaignListStarted(organizationId: 'org-1', userId: 'user-2'),
        );
      await _drainBloc();

      bloc.add(CampaignListDeleteRequested(bloc.state.campaigns.single));
      await _drainBloc();

      expect(bloc.state.deleteStatus, CampaignListDeleteStatus.idle);
      expect(bloc.state.campaigns, isEmpty);
      expect(repository.campaigns['campaign-1']?.deletedAt, isNotNull);
      await bloc.close();
    });

    test('reports a failure loading the campaigns', () async {
      repository.shouldFail = true;

      final bloc = buildBloc()
        ..add(
          const CampaignListStarted(organizationId: 'org-1', userId: 'user-1'),
        );
      await _drainBloc();

      expect(bloc.state.loadStatus, CampaignListLoadStatus.failure);
      await bloc.close();
    });
  });
}

Future<void> _drainBloc() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
