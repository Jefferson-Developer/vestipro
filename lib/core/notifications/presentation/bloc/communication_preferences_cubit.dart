import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../analytics/analytics.dart';
import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/communication_preferences.dart';
import '../../domain/usecases/save_communication_preferences_use_case.dart';
import '../../domain/usecases/watch_communication_preferences_use_case.dart';
import 'communication_preferences_state.dart';

/// Drives the preferences de comunicação screen (TASK-154): stays subscribed
/// to `WatchCommunicationPreferencesUseCase` for the whole lifetime of the
/// screen, so a change saved from another device (or this same one) is
/// reflected live — there is no separate manual "refresh" action, unlike
/// `NotificationCenterBloc`'s one-shot `listForUser`.
@injectable
final class CommunicationPreferencesCubit
    extends Cubit<CommunicationPreferencesState> {
  CommunicationPreferencesCubit(
    this._watchPreferences,
    this._savePreferences,
    this._analyticsService,
  ) : super(const CommunicationPreferencesState());

  final WatchCommunicationPreferencesUseCase _watchPreferences;
  final SaveCommunicationPreferencesUseCase _savePreferences;
  final AnalyticsService _analyticsService;

  StreamSubscription<CommunicationPreferences>? _subscription;

  void start({required String organizationId, required String userId}) {
    if (state.organizationId == organizationId &&
        state.userId == userId &&
        _subscription != null) {
      return;
    }

    unawaited(_subscription?.cancel());
    emit(
      CommunicationPreferencesState(
        status: CommunicationPreferencesLoadStatus.loading,
        organizationId: organizationId,
        userId: userId,
      ),
    );

    _subscription = _watchPreferences(
      organizationId: organizationId,
      userId: userId,
    ).listen(_handlePreferencesChanged, onError: _handleWatchError);
  }

  void _handlePreferencesChanged(CommunicationPreferences preferences) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: CommunicationPreferencesLoadStatus.ready,
        preferences: preferences,
        clearFailure: true,
      ),
    );
  }

  void _handleWatchError(Object error) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: CommunicationPreferencesLoadStatus.failure,
        failure: UnexpectedFailure(
          'Não foi possível carregar suas preferências de comunicação.',
          code: 'communication_preferences_watch_unexpected',
          cause: error,
        ),
      ),
    );
  }

  /// Updates a single `(category, channel)` cell and persists it. The
  /// visible preference only ever changes on success — a rejected update
  /// (e.g. the "categoria Sistema não pode ficar totalmente desativada"
  /// rule) leaves [CommunicationPreferencesState.preferences] exactly as it
  /// was, so the corresponding control in the UI simply reverts on its own.
  Future<void> updateFrequency({
    required AppNotificationCategory category,
    required CommunicationChannel channel,
    required CommunicationFrequency frequency,
  }) async {
    final current = state.preferences;
    if (current == null) return;
    if (state.saveStatus == CommunicationPreferencesSaveStatus.saving) return;

    final candidate = current.withChannelFrequency(
      category: category,
      channel: channel,
      frequency: frequency,
    );

    emit(
      state.copyWith(
        saveStatus: CommunicationPreferencesSaveStatus.saving,
        clearSaveFailure: true,
      ),
    );

    final result = await _savePreferences(preferences: candidate);
    if (isClosed) return;

    switch (result) {
      case AppSuccess<CommunicationPreferences>(value: final saved):
        emit(
          state.copyWith(
            saveStatus: CommunicationPreferencesSaveStatus.success,
            preferences: saved,
            clearSaveFailure: true,
          ),
        );
        await _analyticsService.logEvent(
          AnalyticsEvents.communicationPreferencesUpdated,
          parameters: <String, Object?>{
            'organization_id': saved.organizationId,
            'category': category.name,
            'channel': channel.name,
            'frequency': frequency.name,
          },
        );
      case AppFailure<CommunicationPreferences>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: CommunicationPreferencesSaveStatus.failure,
            saveFailure: failure,
          ),
        );
    }
  }

  void acknowledgeSaveResult() {
    emit(
      state.copyWith(
        saveStatus: CommunicationPreferencesSaveStatus.idle,
        clearSaveFailure: true,
      ),
    );
  }

  @override
  Future<void> close() {
    unawaited(_subscription?.cancel());
    return super.close();
  }
}
