import '../../../../core/errors/errors.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/season.dart';

enum CollectionFormLoadStatus { loading, ready, failure }

enum CollectionFormSubmissionStatus { idle, submitting, success, failure }

final class CollectionFormState {
  const CollectionFormState({
    this.loadStatus = CollectionFormLoadStatus.loading,
    this.submissionStatus = CollectionFormSubmissionStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.initialCollection,
    this.seasons = const <Season>[],
    this.name = '',
    this.seasonId,
    this.year,
    this.startDate,
    this.endDate,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedCollection,
  });

  final CollectionFormLoadStatus loadStatus;
  final CollectionFormSubmissionStatus submissionStatus;
  final String organizationId;
  final String userId;
  final Collection? initialCollection;
  final List<Season> seasons;
  final String name;
  final String? seasonId;
  final int? year;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final Collection? savedCollection;

  bool get isEditing => initialCollection != null;
  bool get isSubmitting =>
      submissionStatus == CollectionFormSubmissionStatus.submitting;

  CollectionFormState copyWith({
    CollectionFormLoadStatus? loadStatus,
    CollectionFormSubmissionStatus? submissionStatus,
    String? organizationId,
    String? userId,
    Collection? initialCollection,
    List<Season>? seasons,
    String? name,
    int? year,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, String>? fieldErrors,
    Failure? failure,
    Collection? savedCollection,
    String? seasonId,
    bool clearSeasonId = false,
    bool clearYear = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearSavedCollection = false,
  }) {
    return CollectionFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      initialCollection: initialCollection ?? this.initialCollection,
      seasons: seasons ?? this.seasons,
      name: name ?? this.name,
      seasonId: clearSeasonId ? null : seasonId ?? this.seasonId,
      year: clearYear ? null : year ?? this.year,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedCollection: clearSavedCollection
          ? null
          : savedCollection ?? this.savedCollection,
    );
  }
}
