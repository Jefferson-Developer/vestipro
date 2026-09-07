import 'dart:async' show unawaited;
import 'dart:developer' as developer;

import 'package:injectable/injectable.dart';

import '../../domain/entities/app_locale.dart';
import '../../domain/repositories/locale_preference_repository.dart';
import '../datasources/locale_preference_data_source.dart';
import '../dtos/locale_preference_dto.dart';
import '../local/locale_preference_local_store.dart';

@LazySingleton(as: LocalePreferenceRepository)
final class LocalePreferenceRepositoryImpl
    implements LocalePreferenceRepository {
  const LocalePreferenceRepositoryImpl({
    required this.localStore,
    required this.dataSource,
  });

  final LocalePreferenceLocalStore localStore;
  final LocalePreferenceDataSource dataSource;

  @override
  Future<AppLocale> getDeviceLocale() async {
    return (await localStore.read()) ?? AppLocale.fallback;
  }

  @override
  Future<void> setDeviceLocale({
    required AppLocale locale,
    required String organizationId,
    required String userId,
  }) async {
    // The local write is the one that matters for `getDeviceLocale`/the
    // running app — it must complete (and can, fully offline) before this
    // method returns, so a caller awaiting it knows the choice already
    // "stuck" on this device regardless of what happens to the Firestore
    // mirror below.
    await localStore.write(locale);

    // Best-effort only, by design (see `LocalePreferenceRepository`'s own
    // doc): never awaited by the caller, and any failure here (offline, no
    // organization/session yet, permission) is swallowed — a language
    // preference is a convenience, never something a user-visible error
    // should be raised for.
    unawaited(_mirrorToFirestore(locale, organizationId, userId));
  }

  Future<void> _mirrorToFirestore(
    AppLocale locale,
    String organizationId,
    String userId,
  ) async {
    try {
      await dataSource.upsert(
        LocalePreferenceDto(
          organizationId: organizationId,
          userId: userId,
          languageCode: locale.languageCode,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to mirror locale preference to Firestore; the local '
        'preference is unaffected.',
        name: 'vestipro.localization',
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
