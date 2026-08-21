import 'package:cloud_firestore/cloud_firestore.dart';

/// A single page of [T] results read from a [FirestoreCollectionDataSource]
/// query, with the cursor needed to fetch the next page.
final class FirestoreQueryPage<T> {
  const FirestoreQueryPage({
    required this.items,
    required this.hasMore,
    this.cursor,
  });

  final List<T> items;
  final bool hasMore;

  /// Pass as `startAfter` to `FirestoreCollectionDataSource.getPage` to
  /// fetch the next page. `null` once [hasMore] is `false`.
  final DocumentSnapshot<T>? cursor;
}
