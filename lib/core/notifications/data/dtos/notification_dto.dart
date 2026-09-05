import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/notifications/{id}` (TASK-151). [id] is
/// never one of the map's keys in [toJson] — Firestore already keys the
/// document by it — same convention as `PushDeviceDto`/`AuditLogEntryDto`.
final class NotificationDto {
  const NotificationDto({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.createdAt,
    this.readAt,
    this.priority = 'informative',
  });

  factory NotificationDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final userId = json['userId'];
    final category = json['category'];
    final title = json['title'];
    final body = json['body'];
    final deepLink = json['deepLink'];
    final createdAt = json['createdAt'];
    final readAt = json['readAt'];
    // Absent on every notification written before TASK-153 shipped this
    // field — defaults to `informative` rather than failing the whole
    // document, unlike every other (always-present-since-TASK-151) field
    // below.
    final priority = json['priority'];

    if (organizationId is! String ||
        userId is! String ||
        category is! String ||
        title is! String ||
        body is! String ||
        deepLink is! String ||
        createdAt is! Timestamp ||
        (readAt != null && readAt is! Timestamp) ||
        (priority != null && priority is! String)) {
      throw const ValidationException(
        'Invalid notification payload.',
        code: 'invalid_notification_payload',
      );
    }

    return NotificationDto(
      id: id,
      organizationId: organizationId,
      userId: userId,
      category: category,
      title: title,
      body: body,
      deepLink: deepLink,
      createdAt: createdAt.toDate(),
      readAt: (readAt as Timestamp?)?.toDate(),
      priority: (priority as String?) ?? 'informative',
    );
  }

  final String id;
  final String organizationId;
  final String userId;

  /// Raw `AppNotificationCategory.name` — kept as a string here so the data
  /// layer never has to depend on the domain enum's exact ordering.
  final String category;
  final String title;
  final String body;
  final String deepLink;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Raw `AppNotificationPriority.name` (TASK-153) — same "string, not the
  /// domain enum" convention as [category].
  final String priority;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'userId': userId,
      'category': category,
      'title': title,
      'body': body,
      'deepLink': deepLink,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt == null ? null : Timestamp.fromDate(readAt!),
      'priority': priority,
    };
  }
}
