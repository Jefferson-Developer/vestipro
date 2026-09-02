import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/insights/insights.dart';

class _MockInsightRepository extends Mock implements InsightRepository {}

void main() {
  group('UpdateInsightStatusUseCase', () {
    late _MockInsightRepository repository;
    late UpdateInsightStatusUseCase useCase;

    setUpAll(() {
      registerFallbackValue(InsightStatus.dismissed);
    });

    setUp(() {
      repository = _MockInsightRepository();
      useCase = UpdateInsightStatusUseCase(repository);
    });

    test('rejects blank organizationId/insightId', () async {
      final result = await useCase(
        organizationId: ' ',
        insightId: ' ',
        status: InsightStatus.dismissed,
      );

      expect(result, isA<AppFailure<void>>());
      expect((result as AppFailure<void>).failure, isA<ValidationFailure>());
      verifyNever(
        () => repository.updateStatus(
          organizationId: any(named: 'organizationId'),
          insightId: any(named: 'insightId'),
          status: any(named: 'status'),
        ),
      );
    });

    test('delegates to the repository with the trimmed ids', () async {
      when(
        () => repository.updateStatus(
          organizationId: 'org-1',
          insightId: 'insight-1',
          status: InsightStatus.dismissed,
        ),
      ).thenAnswer((_) async => const AppSuccess<void>(null));

      final result = await useCase(
        organizationId: ' org-1 ',
        insightId: ' insight-1 ',
        status: InsightStatus.dismissed,
      );

      expect(result, isA<AppSuccess<void>>());
      verify(
        () => repository.updateStatus(
          organizationId: 'org-1',
          insightId: 'insight-1',
          status: InsightStatus.dismissed,
        ),
      ).called(1);
    });
  });
}
