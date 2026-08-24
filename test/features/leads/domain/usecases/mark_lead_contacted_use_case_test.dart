import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';

class _MockLeadRepository extends Mock implements LeadRepository {}

void main() {
  group('MarkLeadContactedUseCase', () {
    late _MockLeadRepository repository;
    late MarkLeadContactedUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildLead(status: LeadStatus.newLead));
    });

    setUp(() {
      repository = _MockLeadRepository();
      useCase = MarkLeadContactedUseCase(repository);
    });

    test('moves a newLead to contacted', () async {
      final lead = _buildLead(status: LeadStatus.newLead);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Lead>(lead));
      when(() => repository.update(lead: any(named: 'lead'))).thenAnswer((
        invocation,
      ) async {
        return AppSuccess<Lead>(invocation.namedArguments[#lead] as Lead);
      });

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'lead-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Lead>>());
      final updated = (result as AppSuccess<Lead>).value;
      expect(updated.status, LeadStatus.contacted);
      expect(updated.contactedAt, isNotNull);
      expect(updated.updatedBy, 'user-2');
      expect(updated.version, lead.version + 1);
      expect(updated.syncStatus, LeadSyncStatus.pending);
    });

    test('blocks moving an already converted lead to contacted', () async {
      final lead = _buildLead(status: LeadStatus.converted);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Lead>(lead));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'lead-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Lead>>());
      expect((result as AppFailure<Lead>).failure, isA<ValidationFailure>());
      verifyNever(() => repository.update(lead: any(named: 'lead')));
    });
  });
}

Lead _buildLead({required LeadStatus status}) {
  final now = DateTime.utc(2026, 1, 1);
  return Lead(
    id: 'lead-1',
    organizationId: 'org-1',
    name: 'Loja Vitrine Moda',
    source: LeadSource.website,
    responsibleUserId: 'user-1',
    status: status,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: LeadSyncStatus.pending,
  );
}
