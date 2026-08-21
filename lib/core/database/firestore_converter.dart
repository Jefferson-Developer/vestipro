/// Standardizes how a Firestore document's `Map<String, dynamic>` payload is
/// converted to/from a strongly-typed [T], so the raw map never has to leave
/// `lib/core/database/`. Feature datasources build one [FirestoreConverter]
/// per entity, delegating to the DTO/mapper pair already established by the
/// Clean Architecture convention (TASK-004): `fromJson` typically wraps a
/// DTO's `fromJson` factory plus its entity mapper, `toJson` the reverse.
final class FirestoreConverter<T> {
  const FirestoreConverter({required this.fromJson, required this.toJson});

  /// Builds a [T] from a document's decoded data and its id.
  final T Function(Map<String, dynamic> data, String id) fromJson;

  /// Serializes a [T] back into the flat map Firestore stores as document
  /// data.
  final Map<String, dynamic> Function(T value) toJson;

  /// [data] is `null` only when Firestore hands back a snapshot with no
  /// data (e.g. a deleted document read from cache); callers still receive
  /// a well-formed [T] instead of a nullable map to check.
  T fromSnapshotData(Map<String, dynamic>? data, String id) {
    return fromJson(data ?? const <String, dynamic>{}, id);
  }

  Map<String, dynamic> toDocumentData(T value) => toJson(value);
}
