import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/collection.dart';
import '../../domain/usecases/close_collection_use_case.dart';
import '../../domain/usecases/list_collections_use_case.dart';
import 'collection_list_event.dart';
import 'collection_list_state.dart';

@injectable
final class CollectionListBloc
    extends Bloc<CollectionListEvent, CollectionListState> {
  CollectionListBloc({
    required this.listCollections,
    required this.closeCollection,
  }) : super(const CollectionListState()) {
    on<CollectionListStarted>(_onStarted, transformer: restartable());
    on<CollectionListRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
    on<CollectionListSearchChanged>(
      _onSearchChanged,
      transformer: sequential(),
    );
    on<CollectionListCloseRequested>(
      _onCloseRequested,
      transformer: sequential(),
    );
  }

  final ListCollectionsUseCase listCollections;
  final CloseCollectionUseCase closeCollection;

  Future<void> _onStarted(
    CollectionListStarted event,
    Emitter<CollectionListState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: CollectionListLoadStatus.loading,
        organizationId: event.organizationId,
        userId: event.userId,
        clearLoadFailure: true,
      ),
    );
    await _load(event.organizationId, emit);
  }

  Future<void> _onRefreshRequested(
    CollectionListRefreshRequested event,
    Emitter<CollectionListState> emit,
  ) async {
    if (state.organizationId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: CollectionListLoadStatus.loading,
        clearLoadFailure: true,
      ),
    );
    await _load(state.organizationId, emit);
  }

  Future<void> _load(
    String organizationId,
    Emitter<CollectionListState> emit,
  ) async {
    final result = await listCollections(organizationId);
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<List<Collection>>(value: final collections):
        emit(
          state.copyWith(
            loadStatus: CollectionListLoadStatus.ready,
            collections: collections,
            clearLoadFailure: true,
          ),
        );
      case AppFailure<List<Collection>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: CollectionListLoadStatus.failure,
            loadFailure: failure,
          ),
        );
    }
  }

  void _onSearchChanged(
    CollectionListSearchChanged event,
    Emitter<CollectionListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onCloseRequested(
    CollectionListCloseRequested event,
    Emitter<CollectionListState> emit,
  ) async {
    emit(
      state.copyWith(
        closeStatus: CollectionListCloseStatus.closing,
        clearCloseFailure: true,
      ),
    );
    final result = await closeCollection(
      organizationId: state.organizationId,
      id: event.collection.id,
      updatedBy: state.userId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<Collection>(value: final closed):
        emit(
          state.copyWith(
            closeStatus: CollectionListCloseStatus.success,
            collections: state.collections
                .map(
                  (collection) =>
                      collection.id == closed.id ? closed : collection,
                )
                .toList(growable: false),
          ),
        );
        emit(state.copyWith(closeStatus: CollectionListCloseStatus.idle));
      case AppFailure<Collection>(failure: final failure):
        emit(
          state.copyWith(
            closeStatus: CollectionListCloseStatus.failure,
            closeFailure: failure,
          ),
        );
    }
  }
}
