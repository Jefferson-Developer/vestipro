import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/privacy/privacy.dart';

void main() {
  testWidgets('lista finalidades separadas, ambas desativadas por padrão', (
    tester,
  ) async {
    final repository = _FakeConsentRepository();
    await tester.pumpWidget(_app(repository));
    repository.emit();
    await tester.pumpAndSettle();

    expect(find.text('Privacidade e consentimentos'), findsOneWidget);
    expect(find.text('Localização'), findsOneWidget);
    expect(find.text('Marketing e novidades'), findsOneWidget);
    expect(find.text('Não concedido'), findsNWidgets(2));
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const ValueKey<String>('consent-location')),
          )
          .value,
      isFalse,
    );
  });

  testWidgets('o mesmo controle concede e revoga em um toque', (tester) async {
    final repository = _FakeConsentRepository();
    await tester.pumpWidget(_app(repository));
    repository.emit();
    await tester.pumpAndSettle();
    final location = find.byKey(const ValueKey<String>('consent-location'));

    await tester.tap(location);
    await tester.pumpAndSettle();
    expect(repository.records.single.granted, isTrue);
    expect(find.textContaining('Concedido em'), findsOneWidget);

    await tester.tap(location);
    await tester.pumpAndSettle();
    expect(repository.records.last.granted, isFalse);
    expect(find.textContaining('Revogado em'), findsOneWidget);
  });
}

Widget _app(_FakeConsentRepository repository) => MaterialApp(
  theme: AppTheme.light,
  home: PrivacyAndConsentsPage(
    createCubit: () => ConsentManagementCubit(
      repository: repository,
      grantConsent: GrantConsent(repository),
      revokeConsent: RevokeConsent(repository),
      organizationId: 'org-a',
      userId: 'user-a',
    ),
    createExportCubit: () {
      final exportRepository = _FakePersonalDataExportRepository();
      return PersonalDataExportCubit(
        repository: exportRepository,
        requestExport: RequestPersonalDataExport(exportRepository),
        getDownload: GetPersonalDataExportDownload(exportRepository),
        organizationId: 'org-a',
        userId: 'user-a',
      );
    },
    onPolicyDocumentsTap: () {},
  ),
);

final class _FakePersonalDataExportRepository
    implements PersonalDataExportRepository {
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
  }) => Stream<AppResult<List<PersonalDataExport>>>.value(
    const AppSuccess<List<PersonalDataExport>>(<PersonalDataExport>[]),
  );
}

final class _FakeConsentRepository implements ConsentRepository {
  final records = <ConsentRecord>[];
  final _changes = StreamController<void>.broadcast();

  void emit() => _changes.add(null);

  @override
  Future<AppResult<void>> appendConsentRecord(ConsentRecord record) async {
    records.add(record);
    emit();
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<List<ConsentRecord>>> listUserConsents({
    required String organizationId,
    required String userId,
  }) async => AppSuccess<List<ConsentRecord>>(records);

  @override
  Stream<AppResult<List<ConsentRecord>>> watchUserConsents({
    required String organizationId,
    required String userId,
  }) => _changes.stream.map(
    (_) => AppSuccess<List<ConsentRecord>>(List.of(records)),
  );
}
