import '../../../../core/errors/errors.dart';
import '../../domain/entities/season.dart';

enum SeasonFormSubmissionStatus { idle, submitting, success, failure }

final class SeasonFormState {
  const SeasonFormState({
    this.submissionStatus = SeasonFormSubmissionStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.initialSeason,
    this.name = '',
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedSeason,
  });

  final SeasonFormSubmissionStatus submissionStatus;
  final String organizationId;
  final String userId;
  final Season? initialSeason;
  final String name;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final Season? savedSeason;

  bool get isEditing => initialSeason != null;
  bool get isSubmitting =>
      submissionStatus == SeasonFormSubmissionStatus.submitting;

  SeasonFormState copyWith({
    SeasonFormSubmissionStatus? submissionStatus,
    String? organizationId,
    String? userId,
    Season? initialSeason,
    String? name,
    Map<String, String>? fieldErrors,
    Failure? failure,
    Season? savedSeason,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearSavedSeason = false,
  }) {
    return SeasonFormState(
      submissionStatus: submissionStatus ?? this.submissionStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      initialSeason: initialSeason ?? this.initialSeason,
      name: name ?? this.name,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedSeason: clearSavedSeason ? null : savedSeason ?? this.savedSeason,
    );
  }
}
