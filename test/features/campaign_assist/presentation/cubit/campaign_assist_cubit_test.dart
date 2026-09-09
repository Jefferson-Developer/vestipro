import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/campaign_assist/campaign_assist.dart';

class _FakeCampaignAssistRepository implements CampaignAssistRepository {
  _FakeCampaignAssistRepository(this._result);

  final AppResult<CampaignCreationDraft> Function() _result;

  @override
  Future<AppResult<CampaignCreationDraft>> generate({
    required String organizationId,
    required List<String> productIds,
    required String audienceDescription,
    required String tone,
    DateTime? startAt,
    DateTime? endAt,
  }) async => _result();
}

CampaignCreationDraft _buildDraft() {
  return CampaignCreationDraft(
    title: 'Verão em Movimento',
    subtitle: 'Leveza e sofisticação para a nova estação',
    description: 'Uma seleção urbana premium para o público certo.',
    citedProductIds: const <String>['p1'],
    generatedAt: DateTime.utc(2026, 9, 7, 10),
    expiresAt: DateTime.utc(2026, 9, 7, 11),
    fromCache: false,
  );
}

void main() {
  group('CampaignAssistCubit', () {
    test('starts idle', () {
      final useCase = GenerateCampaignCreationDraftUseCase(
        _FakeCampaignAssistRepository(
          () => AppSuccess<CampaignCreationDraft>(_buildDraft()),
        ),
        FakeAnalyticsService(),
      );
      final cubit = CampaignAssistCubit(useCase);
      expect(cubit.state.status, CampaignAssistStatus.idle);
      unawaited(cubit.close());
    });

    blocTest<CampaignAssistCubit, CampaignAssistState>(
      'emits [loading, ready] on a successful generate()',
      build: () => CampaignAssistCubit(
        GenerateCampaignCreationDraftUseCase(
          _FakeCampaignAssistRepository(
            () => AppSuccess<CampaignCreationDraft>(_buildDraft()),
          ),
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.generate(
        organizationId: 'org-1',
        productIds: const <String>['p1'],
        audienceDescription: 'Clientes urbanos',
        tone: 'sofisticado',
      ),
      expect: () => <dynamic>[
        isA<CampaignAssistState>().having(
          (state) => state.status,
          'status',
          CampaignAssistStatus.loading,
        ),
        isA<CampaignAssistState>()
            .having(
              (state) => state.status,
              'status',
              CampaignAssistStatus.ready,
            )
            .having((state) => state.draft?.title, 'title', isNotNull),
      ],
    );

    blocTest<CampaignAssistCubit, CampaignAssistState>(
      'emits [loading, error] when the repository fails',
      build: () => CampaignAssistCubit(
        GenerateCampaignCreationDraftUseCase(
          _FakeCampaignAssistRepository(
            () => const AppFailure<CampaignCreationDraft>(
              ServerFailure('Provedor indisponível.', code: 'unavailable'),
            ),
          ),
          FakeAnalyticsService(),
        ),
      ),
      act: (cubit) => cubit.generate(
        organizationId: 'org-1',
        audienceDescription: 'Clientes urbanos',
        tone: 'sofisticado',
      ),
      expect: () => <dynamic>[
        isA<CampaignAssistState>().having(
          (state) => state.status,
          'status',
          CampaignAssistStatus.loading,
        ),
        isA<CampaignAssistState>()
            .having(
              (state) => state.status,
              'status',
              CampaignAssistStatus.error,
            )
            .having(
              (state) => state.failure?.code,
              'failure.code',
              'unavailable',
            ),
      ],
    );

    test('reset() returns to idle while keeping the last draft', () async {
      final useCase = GenerateCampaignCreationDraftUseCase(
        _FakeCampaignAssistRepository(
          () => AppSuccess<CampaignCreationDraft>(_buildDraft()),
        ),
        FakeAnalyticsService(),
      );
      final cubit = CampaignAssistCubit(useCase);
      await cubit.generate(
        organizationId: 'org-1',
        audienceDescription: 'Clientes urbanos',
        tone: 'sofisticado',
      );
      expect(cubit.state.status, CampaignAssistStatus.ready);

      cubit.reset();

      expect(cubit.state.status, CampaignAssistStatus.idle);
      expect(cubit.state.draft, isNotNull);
      await cubit.close();
    });
  });
}
