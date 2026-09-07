import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/cart_share_models.dart';
import '../../domain/usecases/cart_share_use_cases.dart';

enum CartShareStatus { idle, loading, ready, submitted, failure }

final class CartShareState {
  const CartShareState({
    this.status = CartShareStatus.idle,
    this.issued,
    this.preview,
    this.failure,
  });
  final CartShareStatus status;
  final IssuedCartShare? issued;
  final CartSharePreview? preview;
  final Failure? failure;
}

@injectable
final class CartShareCubit extends Cubit<CartShareState> {
  CartShareCubit({
    required this.createCartShare,
    required this.previewCartShare,
    required this.reviewCartShare,
    required this.analytics,
  }) : super(const CartShareState());

  final CreateCartShareUseCase createCartShare;
  final PreviewCartShareUseCase previewCartShare;
  final ReviewCartShareUseCase reviewCartShare;
  final AnalyticsService analytics;

  Future<void> create({
    required String organizationId,
    required String sourceCartId,
    required int sourceCartVersion,
    required List<CartShareDraftItem> items,
    required bool showPrices,
  }) async {
    emit(const CartShareState(status: CartShareStatus.loading));
    final result = await createCartShare(
      organizationId: organizationId,
      sourceCartId: sourceCartId,
      sourceCartVersion: sourceCartVersion,
      items: items,
      showPrices: showPrices,
    );
    switch (result) {
      case AppSuccess<IssuedCartShare>(value: final issued):
        emit(CartShareState(status: CartShareStatus.ready, issued: issued));
        await analytics.logEvent(
          AnalyticsEvents.cartShareCreated,
          parameters: <String, Object?>{
            'items_count': items.length,
            'show_prices': issued.showPrices,
          },
        );
      case AppFailure<IssuedCartShare>(failure: final failure):
        emit(CartShareState(status: CartShareStatus.failure, failure: failure));
    }
  }

  Future<void> load(String token) async {
    emit(const CartShareState(status: CartShareStatus.loading));
    final result = await previewCartShare(token);
    switch (result) {
      case AppSuccess<CartSharePreview>(value: final preview):
        emit(CartShareState(status: CartShareStatus.ready, preview: preview));
      case AppFailure<CartSharePreview>(failure: final failure):
        emit(CartShareState(status: CartShareStatus.failure, failure: failure));
    }
  }

  Future<void> review({
    required String token,
    required CartShareDecision decision,
    String? comment,
    List<String> rejectedItemIds = const <String>[],
  }) async {
    final preview = state.preview;
    emit(CartShareState(status: CartShareStatus.loading, preview: preview));
    final result = await reviewCartShare(
      token: token,
      decision: decision,
      comment: comment,
      rejectedItemIds: rejectedItemIds,
    );
    switch (result) {
      case AppSuccess<void>():
        emit(
          CartShareState(status: CartShareStatus.submitted, preview: preview),
        );
        await analytics.logEvent(
          AnalyticsEvents.cartShareReviewed,
          parameters: <String, Object?>{
            'decision': decision.name,
            'rejected_items_count': rejectedItemIds.length,
          },
        );
      case AppFailure<void>(failure: final failure):
        emit(
          CartShareState(
            status: CartShareStatus.failure,
            preview: preview,
            failure: failure,
          ),
        );
    }
  }
}
