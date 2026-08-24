import '../../domain/entities/customer_portfolio_filters.dart';

sealed class CustomerPortfolioEvent {
  const CustomerPortfolioEvent();
}

final class CustomerPortfolioStarted extends CustomerPortfolioEvent {
  const CustomerPortfolioStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    this.searchQuery = '',
    this.filters = CustomerPortfolioFilters.empty,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String searchQuery;
  final CustomerPortfolioFilters filters;
}

final class CustomerPortfolioSearchChanged extends CustomerPortfolioEvent {
  const CustomerPortfolioSearchChanged(this.searchQuery);

  final String searchQuery;
}

final class CustomerPortfolioFiltersChanged extends CustomerPortfolioEvent {
  const CustomerPortfolioFiltersChanged(this.filters);

  final CustomerPortfolioFilters filters;
}

final class CustomerPortfolioNextPageRequested extends CustomerPortfolioEvent {
  const CustomerPortfolioNextPageRequested();
}

final class CustomerPortfolioRetried extends CustomerPortfolioEvent {
  const CustomerPortfolioRetried();
}

final class CustomerPortfolioSearchDebounced extends CustomerPortfolioEvent {
  const CustomerPortfolioSearchDebounced(this.token);

  final int token;
}
