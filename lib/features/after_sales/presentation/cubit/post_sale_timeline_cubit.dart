import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/watch_post_sale_timeline_for_order_use_case.dart';
import 'post_sale_timeline_state.dart';

/// Feeds the pós-venda timeline embedded in the order detail screen
/// (TASK-201/TASK-102) — every `PostSaleEvent` linked to one pedido, kept
/// live via [WatchPostSaleTimelineForOrderUseCase]'s stream (includes the
/// devolução/troca events auto-appended by TASK-199/TASK-200's own Cloud
/// Functions).
@injectable
final class PostSaleTimelineCubit extends Cubit<PostSaleTimelineState> {
  PostSaleTimelineCubit(this._watchPostSaleTimelineForOrder)
    : super(const PostSaleTimelineState());

  final WatchPostSaleTimelineForOrderUseCase _watchPostSaleTimelineForOrder;
  StreamSubscription<Object?>? _subscription;

  Future<void> watch({
    required String organizationId,
    required String orderId,
  }) async {
    await _subscription?.cancel();
    emit(
      state.copyWith(
        status: PostSaleTimelineStatus.loading,
        clearFailureMessage: true,
      ),
    );
    _subscription =
        _watchPostSaleTimelineForOrder(
          organizationId: organizationId,
          orderId: orderId,
        ).listen((result) {
          result.fold(
            onSuccess: (events) => emit(
              state.copyWith(
                status: events.isEmpty
                    ? PostSaleTimelineStatus.empty
                    : PostSaleTimelineStatus.ready,
                events: events,
              ),
            ),
            onFailure: (failure) => emit(
              state.copyWith(
                status: PostSaleTimelineStatus.error,
                failureMessage: failure.message,
              ),
            ),
          );
        });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
