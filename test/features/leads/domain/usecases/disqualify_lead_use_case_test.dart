import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/leads/leads.dart';

class _MockLeadRepository extends Mock implements LeadRepository {}

void main() {
  group('DisqualifyLeadUseCase', () {
    late _MockLeadRepository repository;
    late DisqualifyLeadUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildLead(status: LeadStatus.contacted));
    });

    setUp(() {
      repository = _MockLeadRepository();
      useCase = DisqualifyLeadUseCase(repository);
    });

    test('disqualifies a contacted lead with a reason', () async {
      final lead = _buildLead(status: LeadStatus.contacted);
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
        reason: ' Sem orcamento disponivel ',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppSuccess<Lead>>());
      final updated = (result as AppSuccess<Lead>).value;
      expect(updated.status, LeadStatus.disqualified);
      expect(updated.disqualificationReason, 'Sem orcamento disponivel');
      expect(updated.version, lead.version + 1);
    });

    test('fails without a disqualification reason', () async {
      final lead = _buildLead(status: LeadStatus.contacted);
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Lead>(lead));

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'lead-1',
        reason: '   ',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Lead>>());
      final failure = (result as AppFailure<Lead>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('reason', 'Disqualification reason is required.'),
      );
      verifyNever(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      );
      verifyNever(() => repository.update(lead: any(named: 'lead')));
    });

    test('blocks disqualifying an already converted lead', () async {
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
        reason: 'Cliente desistiu',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Lead>>());
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
