import '../../domain/entities/post_sale_event.dart';

enum PostSaleTimelineStatus { initial, loading, ready, empty, error }

final class PostSaleTimelineState {
  const PostSaleTimelineState({
    this.status = PostSaleTimelineStatus.initial,
    this.events = const <PostSaleEvent>[],
    this.failureMessage,
  });

  final PostSaleTimelineStatus status;
  final List<PostSaleEvent> events;
  final String? failureMessage;

  PostSaleTimelineState copyWith({
    PostSaleTimelineStatus? status,
    List<PostSaleEvent>? events,
    String? failureMessage,
    bool clearFailureMessage = false,
  }) {
    return PostSaleTimelineState(
      status: status ?? this.status,
      events: events ?? this.events,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
    );
  }
}
