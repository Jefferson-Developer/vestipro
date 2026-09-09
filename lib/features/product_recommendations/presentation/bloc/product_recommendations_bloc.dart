import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../domain/usecases/get_product_recommendations_use_case.dart';
import 'product_recommendations_event.dart';
import 'product_recommendations_state.dart';

/// Drives the "recomendação de produtos" section/sheet (TASK-190, EPIC-28) —
/// a single escopo query, same shape as `DemandForecastBloc` (TASK-185).
@injectable
final class ProductRecommendationsBloc
    extends Bloc<ProductRecommendationsEvent, ProductRecommendationsState> {
  ProductRecommendationsBloc({required this.getRecommendations})
    : super(const ProductRecommendationsState()) {
    on<ProductRecommendationsRequested>(
      _onRequested,
      transformer: restartable(),
    );
    on<ProductRecommendationsRefreshRequested>(
      _onRefreshRequested,
      transformer: restartable(),
    );
  }

  final GetProductRecommendationsUseCase getRecommendations;

  Future<void> _onRequested(
    ProductRecommendationsRequested event,
    Emitter<ProductRecommendationsState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: ProductRecommendationsLoadStatus.loading,
        organizationId: event.organizationId,
        companyId: event.companyId,
        userId: event.userId,
        scopeType: event.scopeType,
        scopeId: event.scopeId,
        clearRecommendation: true,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onRefreshRequested(
    ProductRecommendationsRefreshRequested event,
    Emitter<ProductRecommendationsState> emit,
  ) async {
    if (state.organizationId.isEmpty || state.scopeId.isEmpty) return;
    emit(
      state.copyWith(
        loadStatus: ProductRecommendationsLoadStatus.loading,
        clearFailure: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<ProductRecommendationsState> emit) async {
    final result = await getRecommendations(
      organizationId: state.organizationId,
      companyId: state.companyId,
      requestedByUserId: state.userId,
      scopeType: state.scopeType,
      scopeId: state.scopeId,
    );
    if (emit.isDone) return;

    switch (result) {
      case AppSuccess<ProductRecommendation?>(value: final recommendation):
        emit(
          state.copyWith(
            loadStatus: ProductRecommendationsLoadStatus.ready,
            recommendation: recommendation,
            clearRecommendation: recommendation == null,
            clearFailure: true,
          ),
        );
      case AppFailure<ProductRecommendation?>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: ProductRecommendationsLoadStatus.failure,
            clearRecommendation: true,
            failure: failure,
          ),
        );
    }
  }
}
