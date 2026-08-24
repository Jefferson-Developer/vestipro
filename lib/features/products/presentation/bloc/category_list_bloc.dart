import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/delete_category_use_case.dart';
import '../../domain/usecases/list_categories_use_case.dart';
import '../../domain/usecases/reorder_categories_use_case.dart';
import 'category_list_event.dart';
import 'category_list_state.dart';

@injectable
final class CategoryListBloc
    extends Bloc<CategoryListEvent, CategoryListState> {
  CategoryListBloc({
    required this.listCategories,
    required this.deleteCategory,
    required this.reorderCategories,
  }) : super(const CategoryListState()) {
    on<CategoryListStarted>(_onStarted, transformer: restartable());
    on<CategoryListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<CategoryListSearchChanged>(_onSearchChanged, transformer: sequential());
    on<CategoryListDeleteRequested>(
      _onDeleteRequested,
      transformer: sequential(),
    );
    on<CategoryListReorderRequested>(
      _onReorderRequested,
      transformer: sequential(),
    );
  }

  final ListCategoriesUseCase listCategories;
  final DeleteCategoryUseCase deleteCategory;
  final ReorderCategoriesUseCase reorderCategories;

  Future<void> _onStarted(
    CategoryListStarted event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: CategoryListLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearLoadFailure: true,
      ),
    );
    await _load(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    CategoryListRefreshRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: CategoryListLoadStatus.loading,
        clearLoadFailure: true,
      ),
    );
    await _load(state.organizationId, emit);
  }

  Future<void> _load(
    String organizationId,
    Emitter<CategoryListState> emit,
  ) async {
    final result = await listCategories(organizationId);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<List<Category>>(value: final categories):
        emit(
          state.copyWith(
            loadStatus: CategoryListLoadStatus.ready,
            categories: categories,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<List<Category>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CategoryListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    CategoryListSearchChanged event,
    Emitter<CategoryListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onDeleteRequested(
    CategoryListDeleteRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(
      state.copyWith(
        deleteStatus: CategoryListDeleteStatus.deleting,
        clearDeleteFailure: true,
      ),
    );
    final result = await deleteCategory(
      organizationId: state.organizationId,
      id: event.category.id,
      deletedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Category>():
        emit(
          state.copyWith(
            deleteStatus: CategoryListDeleteStatus.success,
            categories: state.categories
                .where((category) => category.id != event.category.id)
                .toList(growable: false),
          ),
        );
        emit(state.copyWith(deleteStatus: CategoryListDeleteStatus.idle));
      case AppFailure<Category>(failure: final failure):
        emit(
          state.copyWith(
            deleteStatus: CategoryListDeleteStatus.failure,
            deleteFailure: failure,
          ),
        );
    }
  }

  Future<void> _onReorderRequested(
    CategoryListReorderRequested event,
    Emitter<CategoryListState> emit,
  ) async {
    emit(
      state.copyWith(
        reorderStatus: CategoryListReorderStatus.reordering,
        clearReorderFailure: true,
      ),
    );
    final result = await reorderCategories(
      organizationId: state.organizationId,
      parentId: event.parentId,
      orderedIds: event.orderedIds,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<List<Category>>(value: final reordered):
        final byId = <String, Category>{
          for (final category in reordered) category.id: category,
        };
        emit(
          state.copyWith(
            reorderStatus: CategoryListReorderStatus.success,
            categories: state.categories
                .map((category) => byId[category.id] ?? category)
                .toList(growable: false),
          ),
        );
        emit(state.copyWith(reorderStatus: CategoryListReorderStatus.idle));
      case AppFailure<List<Category>>(failure: final failure):
        emit(
          state.copyWith(
            reorderStatus: CategoryListReorderStatus.failure,
            reorderFailure: failure,
          ),
        );
    }
  }
}
