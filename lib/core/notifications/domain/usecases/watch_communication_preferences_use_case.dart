import 'package:injectable/injectable.dart';

import '../entities/communication_preferences.dart';
import '../repositories/communication_preferences_repository.dart';

/// Live subscription to [userId]'s [CommunicationPreferences] (TASK-154),
/// used by the preferences screen so a change saved from another device
/// reaches this one without a manual refresh.
@injectable
final class WatchCommunicationPreferencesUseCase {
  const WatchCommunicationPreferencesUseCase(this._repository);

  final CommunicationPreferencesRepository _repository;

  Stream<CommunicationPreferences> call({
    required String organizationId,
    required String userId,
  }) {
    return _repository.watch(organizationId: organizationId, userId: userId);
  }
}
