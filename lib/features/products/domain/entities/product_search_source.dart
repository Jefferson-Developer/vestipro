/// Source used by global product search.
enum ProductSearchSource { remote, offline }

extension ProductSearchSourceX on ProductSearchSource {
  bool get isPotentiallyStale => this == ProductSearchSource.offline;
}
