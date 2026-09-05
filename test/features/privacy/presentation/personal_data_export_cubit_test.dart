import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/privacy/privacy.dart';

void main() {
  test(
    'reflete solicitado, processando e pronto na ordem do backend',
    () async {
      final repository = _ExportRepository();
      final cubit = PersonalDataExportCubit(
        repository: repository,
        requestExport: RequestPersonalDataExport(repository),
        getDownload: GetPersonalDataExportDownload(repository),
        organizationId: 'org-a',
        userId: 'user-a',
      );
      final seen = <PersonalDataExportStatus>[];
      final subscription = cubit.stream.listen((state) {
        if (state.exports.isNotEmpty) seen.add(state.exports.first.status);
      });

      await cubit.load();
      repository.emit(PersonalDataExportStatus.requested);
      repository.emit(PersonalDataExportStatus.processing);
      repository.emit(PersonalDataExportStatus.ready);
      await Future<void>.delayed(Duration.zero);

      expect(seen, <PersonalDataExportStatus>[
        PersonalDataExportStatus.requested,
        PersonalDataExportStatus.processing,
        PersonalDataExportStatus.ready,
      ]);
      await subscription.cancel();
      await cubit.close();
      await repository.close();
    },
  );
}

final class _ExportRepository implements PersonalDataExportRepository {
  final _controller =
      StreamController<AppResult<List<PersonalDataExport>>>.broadcast(
        sync: true,
      );

  void emit(PersonalDataExportStatus status) => _controller.add(
    AppSuccess<List<PersonalDataExport>>(<PersonalDataExport>[
      PersonalDataExport(
        id: 'export-1',
        organizationId: 'org-a',
        userId: 'user-a',
        status: status,
        requestedAt: DateTime.utc(2026),
        expiresAt: status == PersonalDataExportStatus.ready
            ? DateTime.now().add(const Duration(hours: 1))
            : null,
      ),
    ]),
  );

  Future<void> close() => _controller.close();

  @override
  Future<AppResult<PersonalDataExportDownload>> createDownloadLink({
    required String exportId,
  }) async => AppSuccess<PersonalDataExportDownload>(
    PersonalDataExportDownload(
      url: Uri.parse('https://example.test/export'),
      fileName: 'dados.json',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
    ),
  );

  @override
  Future<AppResult<String>> requestExport({
    required String organizationId,
  }) async => const AppSuccess<String>('export-1');

  @override
  Stream<AppResult<List<PersonalDataExport>>> watchExports({
    required String organizationId,
    required String userId,
  }) => _controller.stream;
}
