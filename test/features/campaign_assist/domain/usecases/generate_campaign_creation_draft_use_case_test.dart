import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/campaign_assist/campaign_assist.dart';

class _FakeCampaignAssistRepository implements CampaignAssistRepository {
  _FakeCampaignAssistRepository(this._result);

  final AppResult<CampaignCreationDraft> _result;
  int callCount = 0;
  List<String>? lastProductIds;

  @override
  Future<AppResult<CampaignCreationDraft>> generate({
    required String organizationId,
    required List<String> productIds,
    required String audienceDescription,
    required String tone,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    callCount += 1;
    lastProductIds = productIds;
    return _result;
  }
}

CampaignCreationDraft _buildDraft({bool fromCache = false}) {
  return CampaignCreationDraft(
    title: 'Verão em Movimento',
    subtitle: 'Leveza e sofisticação para a nova estação',
    description: 'Uma seleção urbana premium para o público certo.',
    citedProductIds: const <String>['p1'],
    generatedAt: DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: fromCache,
  );
}

void main() {
  group('GenerateCampaignCreationDraftUseCase', () {
    test(
      'succeeds, dedups productIds and logs campaignAssistDraftGenerated',
      () async {
        final repository = _FakeCampaignAssistRepository(
          AppSuccess<CampaignCreationDraft>(_buildDraft()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateCampaignCreationDraftUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          productIds: const <String>['p1', 'p1', 'p2'],
          audienceDescription: 'Clientes urbanos',
          tone: 'sofisticado',
        );

        expect(result, isA<AppSuccess<CampaignCreationDraft>>());
        expect(repository.callCount, 1);
        expect(repository.lastProductIds, hasLength(2));
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.campaignAssistDraftGenerated,
          ),
          isTrue,
        );
      },
    );

    test(
      'fails validation without calling the repository for a blank audienceDescription',
      () async {
        final repository = _FakeCampaignAssistRepository(
          AppSuccess<CampaignCreationDraft>(_buildDraft()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateCampaignCreationDraftUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          audienceDescription: '   ',
          tone: 'sofisticado',
        );

        expect(result, isA<AppFailure<CampaignCreationDraft>>());
        expect(
          (result as AppFailure<CampaignCreationDraft>).failure.code,
          'invalid_campaign_assist_request',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test('fails validation when endAt is before startAt', () async {
      final repository = _FakeCampaignAssistRepository(
        AppSuccess<CampaignCreationDraft>(_buildDraft()),
      );
      final useCase = GenerateCampaignCreationDraftUseCase(
        repository,
        FakeAnalyticsService(),
      );

      final result = await useCase(
        organizationId: 'org-1',
        audienceDescription: 'Clientes urbanos',
        tone: 'sofisticado',
        startAt: DateTime.utc(2026, 12, 31),
        endAt: DateTime.utc(2026, 12, 1),
      );

      expect(result, isA<AppFailure<CampaignCreationDraft>>());
      expect(repository.callCount, 0);
    });

    test(
      'propagates a repository failure and logs campaignAssistDraftGenerationFailed',
      () async {
        final repository = _FakeCampaignAssistRepository(
          const AppFailure<CampaignCreationDraft>(
            ConflictFailure(
              'Não foi possível gerar um rascunho confiável.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GenerateCampaignCreationDraftUseCase(
          repository,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          audienceDescription: 'Clientes urbanos',
          tone: 'sofisticado',
        );

        expect(result, isA<AppFailure<CampaignCreationDraft>>());
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name ==
                AnalyticsEvents.campaignAssistDraftGenerationFailed,
          ),
          isTrue,
        );
      },
    );
  });
}
