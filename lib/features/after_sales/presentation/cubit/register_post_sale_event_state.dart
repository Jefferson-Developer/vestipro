import '../../domain/value_objects/post_sale_event_type.dart';

enum RegisterPostSaleEventStatus { idle, submitting, success, failure }

final class RegisterPostSaleEventState {
  const RegisterPostSaleEventState({
    this.status = RegisterPostSaleEventStatus.idle,
    this.type = PostSaleEventType.dispatched,
    this.description,
    this.failureMessage,
    this.fieldErrors = const <String, String>{},
  });

  final RegisterPostSaleEventStatus status;
  final PostSaleEventType type;
  final String? description;
  final String? failureMessage;
  final Map<String, String> fieldErrors;

  RegisterPostSaleEventState copyWith({
    RegisterPostSaleEventStatus? status,
    PostSaleEventType? type,
    String? description,
    String? failureMessage,
    bool clearFailureMessage = false,
    Map<String, String>? fieldErrors,
  }) {
    return RegisterPostSaleEventState(
      status: status ?? this.status,
      type: type ?? this.type,
      description: description ?? this.description,
      failureMessage: clearFailureMessage
          ? null
          : (failureMessage ?? this.failureMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}
