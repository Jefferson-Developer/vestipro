import 'crm_activity.dart';

final class CrmActivityPageResult {
  const CrmActivityPageResult({
    required this.activities,
    required this.hasMore,
    this.nextCursor,
    this.isFromLocalCache = false,
  });

  final List<CrmActivity> activities;
  final bool hasMore;
  final String? nextCursor;
  final bool isFromLocalCache;
}
