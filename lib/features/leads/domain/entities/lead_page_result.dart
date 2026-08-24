import 'lead.dart';

/// One page of [Lead]s returned by [LeadRepository.listPage] (TASK-056),
/// mirroring `CustomerPortfolioPageResult` (TASK-048).
final class LeadPageResult {
  const LeadPageResult({
    required this.leads,
    required this.hasMore,
    this.nextCursor,
    this.isFromLocalCache = false,
  });

  final List<Lead> leads;
  final bool hasMore;
  final String? nextCursor;
  final bool isFromLocalCache;
}
