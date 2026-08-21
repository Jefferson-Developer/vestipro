/// Splits a batch fetched with one extra item (`limit + 1`) into the page to
/// return and whether another page exists, without mutating [fetchedDocs] or
/// any previously returned page.
///
/// [FirestoreCollectionDataSource.getPage] fetches `limit + 1` documents so
/// this can detect `hasMore` without a separate count query; kept as a pure
/// function (generic over any [D], not just Firestore snapshot types) so
/// pagination edge cases are testable without a live Firestore instance.
({List<D> items, bool hasMore}) sliceFetchedPage<D>(
  List<D> fetchedDocs,
  int limit,
) {
  final hasMore = fetchedDocs.length > limit;
  final items = hasMore ? fetchedDocs.sublist(0, limit) : fetchedDocs;
  return (items: List<D>.unmodifiable(items), hasMore: hasMore);
}
