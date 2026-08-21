import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_converter.dart';
import 'firestore_exception_mapper.dart';
import 'firestore_page_slice.dart';
import 'firestore_query_page.dart';

/// Generic, tenant-scoped Firestore access for one collection at
/// `organizations/{organizationId}/{collectionName}`.
///
/// Feature datasources compose this class instead of calling
/// `cloud_firestore` directly, so no `Map<String, dynamic>` or SDK snapshot
/// type ever reaches `domain/`/`presentation/` — every method returns [T]
/// (via [converter]) or a [FirestoreQueryPage] of it.
///
/// Every method requires [organizationId] so a query can never be built
/// without a tenant scope by mistake. This is defense-in-depth only:
/// Firestore Security Rules (TASK-030) remain the real source of truth for
/// tenant isolation, never the client-side query alone.
///
/// Deletion is always a soft delete (see [softDelete]): business documents
/// are never physically removed from Firestore.
final class FirestoreCollectionDataSource<T> {
  FirestoreCollectionDataSource({
    required this.firestore,
    required this.collectionName,
    required this.converter,
  });

  final FirebaseFirestore firestore;
  final String collectionName;
  final FirestoreConverter<T> converter;

  CollectionReference<T> _collection(String organizationId) {
    return firestore
        .collection('organizations')
        .doc(organizationId)
        .collection(collectionName)
        .withConverter<T>(
          fromFirestore: (snapshot, _) =>
              converter.fromSnapshotData(snapshot.data(), snapshot.id),
          toFirestore: (value, _) => converter.toDocumentData(value),
        );
  }

  Future<T?> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final snapshot = await _collection(organizationId).doc(id).get();
      return snapshot.exists ? snapshot.data() : null;
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  Stream<T?> getStream({required String organizationId, required String id}) {
    return _collection(organizationId)
        .doc(id)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot.data() : null)
        .handleError(
          (Object error, StackTrace stackTrace) =>
              throw mapFirestoreExceptionToAppException(
                error as FirebaseException,
                stackTrace,
              ),
          test: (error) => error is FirebaseException,
        );
  }

  /// Fetches one page ordered however [queryBuilder] configures it (apply
  /// `.orderBy` there for a stable cursor across pages). Fetches
  /// `limit + 1` documents to derive [FirestoreQueryPage.hasMore] without a
  /// separate count query; never loads an unbounded/whole collection.
  Future<FirestoreQueryPage<T>> getPage({
    required String organizationId,
    int limit = 20,
    DocumentSnapshot<T>? startAfter,
    Query<T> Function(Query<T> query)? queryBuilder,
  }) async {
    try {
      Query<T> query = _collection(organizationId);
      if (queryBuilder != null) query = queryBuilder(query);
      if (startAfter != null) query = query.startAfterDocument(startAfter);
      query = query.limit(limit + 1);

      final snapshot = await query.get();
      final sliced = sliceFetchedPage<QueryDocumentSnapshot<T>>(
        snapshot.docs,
        limit,
      );

      return FirestoreQueryPage<T>(
        items: sliced.items.map((doc) => doc.data()).toList(growable: false),
        hasMore: sliced.hasMore,
        cursor: sliced.items.isNotEmpty ? sliced.items.last : startAfter,
      );
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  /// Reactive equivalent of [getPage] without cursor pagination — only for
  /// small, explicitly bounded result sets (e.g. `limit: 50`). Screens that
  /// paginate must use [getPage] instead of raising this limit.
  Stream<List<T>> watchQuery({
    required String organizationId,
    int? limit,
    Query<T> Function(Query<T> query)? queryBuilder,
  }) {
    Query<T> query = _collection(organizationId);
    if (queryBuilder != null) query = queryBuilder(query);
    if (limit != null) query = query.limit(limit);

    return query
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc.data()).toList(growable: false),
        )
        .handleError(
          (Object error, StackTrace stackTrace) =>
              throw mapFirestoreExceptionToAppException(
                error as FirebaseException,
                stackTrace,
              ),
          test: (error) => error is FirebaseException,
        );
  }

  Future<void> set({
    required String organizationId,
    required String id,
    required T value,
    bool merge = false,
  }) async {
    try {
      await _collection(
        organizationId,
      ).doc(id).set(value, SetOptions(merge: merge));
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  Future<void> update({
    required String organizationId,
    required String id,
    required Map<String, Object?> data,
  }) async {
    try {
      await _collection(organizationId).doc(id).update(data);
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  /// Marks the document deleted without removing it: sets `deletedAt`
  /// instead of calling Firestore's `delete()`.
  Future<void> softDelete({
    required String organizationId,
    required String id,
    required DateTime deletedAt,
  }) {
    return update(
      organizationId: organizationId,
      id: id,
      data: {'deletedAt': Timestamp.fromDate(deletedAt)},
    );
  }
}
