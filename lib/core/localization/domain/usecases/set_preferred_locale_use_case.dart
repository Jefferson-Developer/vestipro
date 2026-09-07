import 'package:injectable/injectable.dart';

import '../entities/app_locale.dart';
import '../repositories/locale_preference_repository.dart';

/// Persists the user's chosen interface language (TASK-174) — see
/// `LocalePreferenceRepository.setDeviceLocale` for the local-first,
/// best-effort-remote-mirror contract this simply forwards to. No business
/// rule to enforce here (unlike, say,
/// `SaveCommunicationPreferencesUseCase`'s "system category" guard): every
/// [AppLocale] value is always a valid choice.
@injectable
final class SetPreferredLocaleUseCase {
  const SetPreferredLocaleUseCase(this._repository);

  final LocalePreferenceRepository _repository;

  Future<void> call({
    required AppLocale locale,
    required String organizationId,
    required String userId,
  }) {
    return _repository.setDeviceLocale(
      locale: locale,
      organizationId: organizationId,
      userId: userId,
    );
  }
}
