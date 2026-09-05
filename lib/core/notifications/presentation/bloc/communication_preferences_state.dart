import '../../../errors/errors.dart';
import '../../domain/entities/communication_preferences.dart';

enum CommunicationPreferencesLoadStatus { initial, loading, ready, failure }

enum CommunicationPreferencesSaveStatus { idle, saving, success, failure }

final class CommunicationPreferencesState {
  const CommunicationPreferencesState({
    this.status = CommunicationPreferencesLoadStatus.initial,
    this.saveStatus = CommunicationPreferencesSaveStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.preferences,
    this.failure,
    this.saveFailure,
  });

  final CommunicationPreferencesLoadStatus status;
  final CommunicationPreferencesSaveStatus saveStatus;
  final String organizationId;
  final String userId;

  /// `null` until the first value arrives from `WatchCommunicationPreferencesUseCase`.
  final CommunicationPreferences? preferences;

  final Failure? failure;
  final Failure? saveFailure;

  bool get isLoading =>
      status == CommunicationPreferencesLoadStatus.initial ||
      status == CommunicationPreferencesLoadStatus.loading;

  CommunicationPreferencesState copyWith({
    CommunicationPreferencesLoadStatus? status,
    CommunicationPreferencesSaveStatus? saveStatus,
    String? organizationId,
    String? userId,
    CommunicationPreferences? preferences,
    Failure? failure,
    bool clearFailure = false,
    Failure? saveFailure,
    bool clearSaveFailure = false,
  }) {
    return CommunicationPreferencesState(
      status: status ?? this.status,
      saveStatus: saveStatus ?? this.saveStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      preferences: preferences ?? this.preferences,
      failure: clearFailure ? null : failure ?? this.failure,
      saveFailure: clearSaveFailure ? null : saveFailure ?? this.saveFailure,
    );
  }
}
