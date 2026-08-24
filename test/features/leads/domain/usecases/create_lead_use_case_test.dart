import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';

class _MockLeadRepository extends Mock implements LeadRepository {}

void main() {
  group('CreateLeadUseCase', () {
    late _MockLeadRepository repository;
    late CreateLeadUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildLead());
    });

    setUp(() {
      repository = _MockLeadRepository();
      useCase = CreateLeadUseCase(repository);
    });

    test('creates a lead as newLead after trimming the payload', () async {
      when(
        () => repository.create(lead: any(named: 'lead')),
      ).thenAnswer((_) async => AppSuccess<Lead>(_buildLead()));

      final result = await useCase.call(
        id: ' lead-1 ',
        organizationId: ' org-1 ',
        name: ' Loja Vitrine Moda ',
        source: LeadSource.website,
        responsibleUserId: ' user-1 ',
        createdBy: ' user-1 ',
      );

      expect(result, isA<AppSuccess<Lead>>());
      final captured =
          verify(
                () => repository.create(lead: captureAny(named: 'lead')),
              ).captured.single
              as Lead;
      expect(captured.id, 'lead-1');
      expect(captured.organizationId, 'org-1');
      expect(captured.name, 'Loja Vitrine Moda');
      expect(captured.responsibleUserId, 'user-1');
      expect(captured.source, LeadSource.website);
      expect(captured.status, LeadStatus.newLead);
      expect(captured.score, 0);
      expect(captured.createdBy, 'user-1');
      expect(captured.updatedBy, 'user-1');
      expect(captured.version, 1);
      expect(captured.syncStatus, LeadSyncStatus.pending);
    });

    test('rejects an absent organization id', () async {
      final result = await useCase.call(
        id: 'lead-1',
        organizationId: '  ',
        name: 'Loja Vitrine Moda',
        source: LeadSource.website,
        responsibleUserId: 'user-1',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Lead>>());
      final failure = (result as AppFailure<Lead>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('organizationId', 'OrganizationId is required.'),
      );
      verifyNever(() => repository.create(lead: any(named: 'lead')));
    });

    test('rejects an absent responsible user', () async {
      final result = await useCase.call(
        id: 'lead-1',
        organizationId: 'org-1',
        name: 'Loja Vitrine Moda',
        source: LeadSource.website,
        responsibleUserId: '  ',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Lead>>());
      final failure = (result as AppFailure<Lead>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('responsibleUserId', 'ResponsibleUserId is required.'),
      );
      verifyNever(() => repository.create(lead: any(named: 'lead')));
    });
  });
}

Lead _buildLead() {
  final now = DateTime.utc(2026, 1, 1);
  return Lead(
    id: 'lead-1',
    organizationId: 'org-1',
    name: 'Loja Vitrine Moda',
    source: LeadSource.website,
    responsibleUserId: 'user-1',
    status: LeadStatus.newLead,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: LeadSyncStatus.pending,
  );
}
