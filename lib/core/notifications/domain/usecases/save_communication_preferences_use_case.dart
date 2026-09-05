import 'package:injectable/injectable.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../entities/communication_preferences.dart';
import '../repositories/communication_preferences_repository.dart';

/// Validates and persists a new [CommunicationPreferences] state (TASK-154).
///
/// The one business rule enforced here — never in the repository/data
/// source, and never left to Firestore Rules alone — is "notificações
/// críticas de sistema... não podem ser completamente desativadas": a save
/// that would leave [AppNotificationCategory.system] with every channel
/// disabled is rejected with a [ValidationFailure] before anything is
/// persisted, leaving the previous (still valid) preference untouched.
@injectable
final class SaveCommunicationPreferencesUseCase {
  const SaveCommunicationPreferencesUseCase(this._repository);

  final CommunicationPreferencesRepository _repository;

  Future<AppResult<CommunicationPreferences>> call({
    required CommunicationPreferences preferences,
  }) {
    if (preferences.hasSystemCategoryFullyDisabled) {
      return Future.value(
        AppFailure<CommunicationPreferences>(
          const ValidationFailure(
            'A categoria Sistema precisa manter ao menos um canal de '
            'notificação ativo.',
            code: 'system_category_fully_disabled',
          ),
        ),
      );
    }
    return _repository.save(preferences: preferences);
  }
}
