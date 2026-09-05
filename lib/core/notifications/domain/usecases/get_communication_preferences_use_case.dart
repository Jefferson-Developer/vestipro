import 'package:injectable/injectable.dart';

import '../../../utils/utils.dart';
import '../entities/communication_preferences.dart';
import '../repositories/communication_preferences_repository.dart';

/// One-shot read of [userId]'s current [CommunicationPreferences] (TASK-154)
/// — [CommunicationPreferencesCubit] instead uses `WatchCommunicationPreferencesUseCase`
/// for the actual preferences screen, since that one stays live across
/// cross-device changes; this use case exists for any one-off caller that
/// only needs a snapshot.
@injectable
final class GetCommunicationPreferencesUseCase {
  const GetCommunicationPreferencesUseCase(this._repository);

  final CommunicationPreferencesRepository _repository;

  Future<AppResult<CommunicationPreferences>> call({
    required String organizationId,
    required String userId,
  }) {
    return _repository.get(organizationId: organizationId, userId: userId);
  }
}
