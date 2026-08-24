import 'customer.dart';

final class CustomerPortfolioPageResult {
  const CustomerPortfolioPageResult({
    required this.customers,
    required this.hasMore,
    this.nextCursor,
    this.isFromLocalCache = false,
  });

  final List<Customer> customers;
  final bool hasMore;
  final String? nextCursor;
  final bool isFromLocalCache;
}
