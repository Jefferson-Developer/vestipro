import '../../../../core/errors/errors.dart';

/// Shape of `registerPostSaleEvent`'s callable response.
final class PostSaleEventSubmissionResultDto {
  const PostSaleEventSubmissionResultDto({
    required this.eventId,
    required this.orderId,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory PostSaleEventSubmissionResultDto.fromJson(Map<String, dynamic> json) {
    final eventId = json['eventId'];
    final orderId = json['orderId'];
    final type = json['type'];
    final description = json['description'];
    final createdAt = json['createdAt'];
    if (eventId is! String ||
        orderId is! String ||
        type is! String ||
        (description != null && description is! String) ||
        createdAt is! String) {
      throw const ValidationException(
        'Invalid registerPostSaleEvent response payload.',
        code: 'invalid_post_sale_event_submission_result_payload',
      );
    }
    return PostSaleEventSubmissionResultDto(
      eventId: eventId,
      orderId: orderId,
      type: type,
      description: description as String?,
      createdAt: DateTime.parse(createdAt),
    );
  }

  final String eventId;
  final String orderId;
  final String type;
  final String? description;
  final DateTime createdAt;
}
