import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('RegisterCrmActivityUseCase', () {
    late _InMemoryCrmActivityRepository repository;
    late RegisterCrmActivityUseCase useCase;

    setUp(() {
      repository = _InMemoryCrmActivityRepository();
      useCase = RegisterCrmActivityUseCase(repository);
    });

    test('requires a customer, lead or opportunity link', () async {
      final result = await useCase(
        id: 'activity-1',
        organizationId: 'org-1',
        userId: 'rep-1',
        type: CrmActivityType.phoneCall,
        description: 'Ligacao realizada',
      );

      expect(result, isA<AppFailure<CrmActivity>>());
      final failure = (result as AppFailure<CrmActivity>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, contains('link'));
      expect(repository.activities, isEmpty);
    });

    test(
      'registers pending offline activity with authenticated author',
      () async {
        final result = await useCase(
          id: 'activity-1',
          organizationId: 'org-1',
          customerId: 'customer-1',
          userId: 'rep-1',
          type: CrmActivityType.visit,
          description: 'Visita para revisar grade',
          durationMinutes: 45,
          attachmentUrls: const <String>[' ', 'https://example.com/a.pdf'],
        );

        expect(result, isA<AppSuccess<CrmActivity>>());
        final activity = (result as AppSuccess<CrmActivity>).value;
        expect(activity.customerId, 'customer-1');
        expect(activity.userId, 'rep-1');
        expect(activity.createdBy, 'rep-1');
        expect(activity.syncStatus, CrmActivitySyncStatus.pending);
        expect(activity.attachmentUrls, const <String>[
          'https://example.com/a.pdf',
        ]);
        expect(repository.activities.single, activity);
      },
    );
  });
}

final class _InMemoryCrmActivityRepository implements CrmActivityRepository {
  final List<CrmActivity> activities = <CrmActivity>[];

  @override
  Future<AppResult<CrmActivity>> create({required CrmActivity activity}) async {
    activities.add(activity);
    return AppSuccess<CrmActivity>(activity);
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForCustomer({
    required String organizationId,
    required String customerId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForLead({
    required String organizationId,
    required String leadId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<CrmActivityPageResult>> listForOpportunity({
    required String organizationId,
    required String opportunityId,
    int limit = 20,
    String? cursor,
    bool ascending = false,
  }) {
    throw UnimplementedError();
  }
}
