import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/visit_routes/visit_routes.dart';

void main() {
  group('GetActiveVisitRouteUseCase (TASK-177)', () {
    test('normalizes the requested date to a UTC-midnight day key', () async {
      final repository = _RecordingVisitRouteRepository();
      final useCase = GetActiveVisitRouteUseCase(repository);

      await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
        date: DateTime.utc(2026, 9, 7, 18, 30),
      );

      expect(repository.lastRequestedDate, DateTime.utc(2026, 9, 7));
    });

    test('defaults to "today" when no date is provided', () async {
      final repository = _RecordingVisitRouteRepository();
      final useCase = GetActiveVisitRouteUseCase(repository);

      await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        salesRepId: 'rep-1',
      );

      expect(repository.lastRequestedDate, VisitRoute.dateKey(DateTime.now()));
    });
  });
}

class _RecordingVisitRouteRepository implements VisitRouteRepository {
  DateTime? lastRequestedDate;

  @override
  Future<AppResult<VisitRoute?>> getForDate({
    required String organizationId,
    required String companyId,
    required String salesRepId,
    required DateTime date,
  }) async {
    lastRequestedDate = date;
    return const AppSuccess<VisitRoute?>(null);
  }

  @override
  Future<AppResult<VisitRoute>> save(VisitRoute route) async {
    return AppSuccess<VisitRoute>(route);
  }
}
