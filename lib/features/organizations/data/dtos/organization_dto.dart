import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import 'organization_settings_dto.dart';

/// Firestore document shape for `organizations/{id}` (TASK-026). [id] is
/// never one of the map's keys in [toJson] — Firestore already keys the
/// document by it — so it must always be supplied out-of-band (the document
/// snapshot's own id) when building one from [fromJson].
final class OrganizationDto {
  const OrganizationDto({
    required this.id,
    required this.name,
    required this.slug,
    required this.settings,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });

  factory OrganizationDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final name = json['name'];
    final slug = json['slug'];
    final settingsJson = json['settings'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final deletedAt = json['deletedAt'];

    if (name is! String ||
        slug is! String ||
        settingsJson is! Map<String, dynamic> ||
        status is! String ||
        createdAt is! Timestamp ||
        createdBy is! String ||
        updatedAt is! Timestamp ||
        updatedBy is! String ||
        (deletedAt != null && deletedAt is! Timestamp)) {
      throw const ValidationException(
        'Invalid organization payload.',
        code: 'invalid_organization_payload',
      );
    }

    return OrganizationDto(
      id: id,
      name: name,
      slug: slug,
      settings: OrganizationSettingsDto.fromJson(settingsJson),
      status: status,
      createdAt: createdAt.toDate(),
      createdBy: createdBy,
      updatedAt: updatedAt.toDate(),
      updatedBy: updatedBy,
      deletedAt: (deletedAt as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String name;
  final String slug;
  final OrganizationSettingsDto settings;
  final String status;
  final DateTime createdAt;
  final String createdBy;
  final DateTime updatedAt;
  final String updatedBy;
  final DateTime? deletedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'slug': slug,
      'settings': settings.toJson(),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt == null ? null : Timestamp.fromDate(deletedAt!),
    };
  }
}
