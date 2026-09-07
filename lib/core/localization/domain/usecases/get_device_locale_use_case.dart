import 'package:injectable/injectable.dart';

import '../entities/app_locale.dart';
import '../repositories/locale_preference_repository.dart';

/// Reads the language this device currently boots the interface with
/// (TASK-174) — always offline-safe, see
/// `LocalePreferenceRepository.getDeviceLocale`.
@injectable
final class GetDeviceLocaleUseCase {
  const GetDeviceLocaleUseCase(this._repository);

  final LocalePreferenceRepository _repository;

  Future<AppLocale> call() {
    return _repository.getDeviceLocale();
  }
}
