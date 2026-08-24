import 'package:freezed_annotation/freezed_annotation.dart';

part 'season.freezed.dart';

/// Fashion calendar season vocabulary, shared across every `Collection` of
/// one Organization (TASK-066), e.g. "Verão", "Inverno", or a custom season
/// name a multi-brand Organization defines for itself.
///
/// [name] uniqueness (case-insensitive, trimmed) among non-deleted Seasons
/// of the same [organizationId] is enforced by `CreateSeasonUseCase`/
/// `UpdateSeasonUseCase`, never by this entity or by UI widgets. Season
/// belongs to exactly one [organizationId] — never shared between tenants.
@freezed
abstract class Season with _$Season {
  const factory Season({
    required String id,
    required String organizationId,
    required String name,
    required int version,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
  }) = _Season;
}
