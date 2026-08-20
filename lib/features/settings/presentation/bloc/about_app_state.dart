import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/about_app.dart';
import '../../domain/entities/about_app_data_origin.dart';
import '../../domain/entities/about_app_note.dart';

part 'about_app_state.freezed.dart';

enum AboutAppSubmissionStatus { idle, submitting, submitted, failure }

@freezed
sealed class AboutAppState with _$AboutAppState {
  const factory AboutAppState.initial({
    @Default(AboutAppDataOrigin.localCache) AboutAppDataOrigin dataOrigin,
  }) = AboutAppInitial;

  const factory AboutAppState.loading({
    AboutApp? aboutApp,
    @Default(<AboutAppNote>[]) List<AboutAppNote> notes,
    @Default('') String query,
    @Default(0) int page,
    @Default(true) bool hasMore,
    @Default(AboutAppDataOrigin.localCache) AboutAppDataOrigin dataOrigin,
  }) = AboutAppLoading;

  const factory AboutAppState.ready({
    required AboutApp aboutApp,
    required List<AboutAppNote> notes,
    required int page,
    required bool hasMore,
    required String query,
    required AboutAppDataOrigin dataOrigin,
    @Default(false) bool isLoadingNextPage,
    @Default(AboutAppSubmissionStatus.idle)
    AboutAppSubmissionStatus submissionStatus,
    Failure? submissionFailure,
  }) = AboutAppReady;

  const factory AboutAppState.failure({
    required Failure failure,
    AboutApp? aboutApp,
    @Default(<AboutAppNote>[]) List<AboutAppNote> notes,
    @Default('') String query,
    @Default(0) int page,
    @Default(false) bool hasMore,
    @Default(AboutAppDataOrigin.localCache) AboutAppDataOrigin dataOrigin,
  }) = AboutAppFailure;
}
