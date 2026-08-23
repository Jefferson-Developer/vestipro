import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../dtos/onboarding_progress_dto.dart';
import 'onboarding_progress_data_source.dart';

/// [OnboardingProgressDataSource] backed by `shared_preferences` (TASK-038).
///
/// Deliberately not `flutter_secure_storage`: unlike a session
/// token/credential (TASK-041's concern), the wizard's in-progress answers
/// are not sensitive, and `shared_preferences` is the same mechanism
/// `tasks.md`'s own scope note for this task suggests. Each call resolves
/// [SharedPreferences.getInstance] itself instead of caching the instance
/// at construction time — the plugin already caches it internally after the
/// first call, and this keeps this datasource out of `AppInjectionModule`'s
/// Firebase-product wiring (no async `@preResolve` needed).
@LazySingleton(as: OnboardingProgressDataSource)
final class SharedPreferencesOnboardingProgressDataSource
    implements OnboardingProgressDataSource {
  const SharedPreferencesOnboardingProgressDataSource();

  String _keyFor(String userId) => 'onboarding_progress_$userId';

  @override
  Future<OnboardingProgressDto?> getProgress({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(userId));
    if (raw == null) {
      return null;
    }

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      return OnboardingProgressDto.fromJson(json);
    } on FormatException {
      // Corrupted/unparseable local cache: resume with a clean slate
      // instead of surfacing a technical error the user cannot act on.
      return null;
    } on ValidationException {
      // Same rationale: a saved payload with an unexpected shape (e.g.
      // written by a future app version) must not crash the wizard either.
      return null;
    }
  }

  @override
  Future<void> saveProgress({
    required String userId,
    required OnboardingProgressDto progress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(userId), jsonEncode(progress.toJson()));
  }

  @override
  Future<void> clearProgress({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(userId));
  }
}
