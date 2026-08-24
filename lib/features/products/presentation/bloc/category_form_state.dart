import '../../../../core/errors/errors.dart';
import '../../domain/entities/category.dart';

enum CategoryFormLoadStatus { loading, ready, failure }

enum CategoryFormSubmissionStatus { idle, submitting, success, failure }

final class CategoryFormState {
  const CategoryFormState({
    this.loadStatus = CategoryFormLoadStatus.loading,
    this.submissionStatus = CategoryFormSubmissionStatus.idle,
    this.organizationId = '',
    this.userId = '',
    this.initialCategory,
    this.availableParents = const <Category>[],
    this.name = '',
    this.parentId,
    this.fieldErrors = const <String, String>{},
    this.failure,
    this.savedCategory,
  });

  final CategoryFormLoadStatus loadStatus;
  final CategoryFormSubmissionStatus submissionStatus;
  final String organizationId;
  final String userId;
  final Category? initialCategory;

  /// Every Category eligible as a parent for the one being edited/created:
  /// the whole organization tree minus the Category itself and any of its
  /// descendants (never offered, since picking one would be rejected by
  /// `CategoryCycleValidator` anyway).
  final List<Category> availableParents;
  final String name;
  final String? parentId;
  final Map<String, String> fieldErrors;
  final Failure? failure;
  final Category? savedCategory;

  bool get isEditing => initialCategory != null;
  bool get isSubmitting =>
      submissionStatus == CategoryFormSubmissionStatus.submitting;

  CategoryFormState copyWith({
    CategoryFormLoadStatus? loadStatus,
    CategoryFormSubmissionStatus? submissionStatus,
    String? organizationId,
    String? userId,
    Category? initialCategory,
    List<Category>? availableParents,
    String? name,
    String? parentId,
    Map<String, String>? fieldErrors,
    Failure? failure,
    Category? savedCategory,
    bool clearParentId = false,
    bool clearFieldErrors = false,
    bool clearFailure = false,
    bool clearSavedCategory = false,
  }) {
    return CategoryFormState(
      loadStatus: loadStatus ?? this.loadStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      organizationId: organizationId ?? this.organizationId,
      userId: userId ?? this.userId,
      initialCategory: initialCategory ?? this.initialCategory,
      availableParents: availableParents ?? this.availableParents,
      name: name ?? this.name,
      parentId: clearParentId ? null : parentId ?? this.parentId,
      fieldErrors: clearFieldErrors
          ? const <String, String>{}
          : fieldErrors ?? this.fieldErrors,
      failure: clearFailure ? null : failure ?? this.failure,
      savedCategory: clearSavedCategory
          ? null
          : savedCategory ?? this.savedCategory,
    );
  }
}
