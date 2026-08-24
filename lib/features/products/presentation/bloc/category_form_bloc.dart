import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/create_category_use_case.dart';
import '../../domain/usecases/list_categories_use_case.dart';
import '../../domain/usecases/update_category_use_case.dart';
import 'category_form_event.dart';
import 'category_form_state.dart';

@injectable
final class CategoryFormBloc
    extends Bloc<CategoryFormEvent, CategoryFormState> {
  CategoryFormBloc({
    required this.listCategories,
    required this.createCategory,
    required this.updateCategory,
  }) : super(const CategoryFormState()) {
    on<CategoryFormStarted>(_onStarted, transformer: restartable());
    on<CategoryFormNameChanged>(_onNameChanged, transformer: sequential());
    on<CategoryFormParentSelected>(
      _onParentSelected,
      transformer: sequential(),
    );
    on<CategoryFormSubmitted>(_onSubmitted, transformer: sequential());
  }

  final ListCategoriesUseCase listCategories;
  final CreateCategoryUseCase createCategory;
  final UpdateCategoryUseCase updateCategory;
  final Uuid _uuid = const Uuid();

  Future<void> _onStarted(
    CategoryFormStarted event,
    Emitter<CategoryFormState> emit,
  ) async {
    final initial = event.initialCategory;
    emit(
      CategoryFormState(
        loadStatus: CategoryFormLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        initialCategory: initial,
        name: initial?.name ?? '',
        parentId: initial?.parentId ?? event.initialParentId,
      ),
    );

    final result = await listCategories(event.organizationId);
    if (emit.isDone) return;
    switch (result) {
      case AppSuccess<List<Category>>(value: final categories):
        emit(
          state.copyWith(
            loadStatus: CategoryFormLoadStatus.ready,
            availableParents: initial == null
                ? categories
                : _excludingSelfAndDescendants(categories, initial.id),
            clearFailure: true,
          ),
        );
      case AppFailure<List<Category>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CategoryFormLoadStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  List<Category> _excludingSelfAndDescendants(
    List<Category> categories,
    String categoryId,
  ) {
    final excluded = <String>{categoryId};
    var addedMore = true;
    while (addedMore) {
      addedMore = false;
      for (final category in categories) {
        final parentId = category.parentId;
        if (parentId != null &&
            excluded.contains(parentId) &&
            excluded.add(category.id)) {
          addedMore = true;
        }
      }
    }
    return categories
        .where((category) => !excluded.contains(category.id))
        .toList(growable: false);
  }

  void _onNameChanged(
    CategoryFormNameChanged event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(
      state.copyWith(
        name: event.name,
        submissionStatus: CategoryFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  void _onParentSelected(
    CategoryFormParentSelected event,
    Emitter<CategoryFormState> emit,
  ) {
    emit(
      state.copyWith(
        parentId: event.parentId,
        clearParentId: event.parentId == null,
        submissionStatus: CategoryFormSubmissionStatus.idle,
        clearFieldErrors: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    CategoryFormSubmitted event,
    Emitter<CategoryFormState> emit,
  ) async {
    if (state.name.trim().isEmpty) {
      emit(
        state.copyWith(
          submissionStatus: CategoryFormSubmissionStatus.failure,
          fieldErrors: const <String, String>{
            'name': 'Informe o nome da categoria.',
          },
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        submissionStatus: CategoryFormSubmissionStatus.submitting,
        clearFieldErrors: true,
        clearFailure: true,
        clearSavedCategory: true,
      ),
    );

    final result = state.isEditing
        ? await updateCategory(
            organizationId: state.organizationId,
            id: state.initialCategory!.id,
            name: state.name,
            parentId: state.parentId,
            updatedBy: state.userId,
          )
        : await createCategory(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            name: state.name,
            parentId: state.parentId,
            createdBy: state.userId,
          );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Category>(value: final category):
        emit(
          state.copyWith(
            submissionStatus: CategoryFormSubmissionStatus.success,
            savedCategory: category,
            clearFailure: true,
          ),
        );
      case AppFailure<Category>(failure: final failure):
        emit(
          state.copyWith(
            submissionStatus: CategoryFormSubmissionStatus.failure,
            failure: failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
          ),
        );
    }
  }
}
