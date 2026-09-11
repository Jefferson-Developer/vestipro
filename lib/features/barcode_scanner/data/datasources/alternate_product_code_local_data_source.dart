import '../../domain/entities/alternate_product_code.dart';

/// Local-only persistence for [AlternateProductCode] (TASK-216) — the
/// "índice local offline" of registered code corrections, so a garment
/// scanned with a legacy/reprinted barcode still resolves without network,
/// same offline-first precedent `SharedPreferencesProductVariantRepository`
/// already sets for the rest of the offline catalog cache.
abstract interface class AlternateProductCodeLocalDataSource {
  /// `null` when [code] (already normalized by
  /// `ScannedCodeClassifier.comparableValue`) has no registered mapping in
  /// [organizationId].
  Future<AlternateProductCode?> findByCode({
    required String organizationId,
    required String code,
  });

  Future<List<AlternateProductCode>> listByOrganization(String organizationId);

  /// Inserts or overwrites the mapping for [code] — the same code registered
  /// twice (e.g. a correction) simply replaces the previous target instead
  /// of erroring, since there is exactly one valid target for a given code
  /// at any point in time.
  Future<AlternateProductCode> upsert(AlternateProductCode code);
}
