import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import 'fulfillment_write_data_source.dart';

/// [FulfillmentWriteDataSource] backed by [CloudFunctionsService] (TASK-214)
/// — every mutation goes through the `registerLogisticsIssue`/
/// `resolveLogisticsIssue` callables, never a direct Firestore write, same
/// contract `CloudFunctionsReceivablesWriteDataSource` (TASK-213) already
/// follows. `createShipment`/`registerTrackingEvent` are deliberately not
/// exposed here yet — see this task's "Pendências" for the documented scope
/// decision.
@LazySingleton(as: FulfillmentWriteDataSource)
final class CloudFunctionsFulfillmentWriteDataSource
    implements FulfillmentWriteDataSource {
  const CloudFunctionsFulfillmentWriteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<void> registerLogisticsIssue({
    required String organizationId,
    required String companyId,
    required String shipmentId,
    required String logisticsIssueId,
    required String type,
    required String description,
    required String responsibleUserId,
    required String nextAction,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'registerLogisticsIssue',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'shipmentId': shipmentId,
        'logisticsIssueId': logisticsIssueId,
        'type': type,
        'description': description,
        'responsibleUserId': responsibleUserId,
        'nextAction': nextAction,
      },
    );
  }

  @override
  Future<void> resolveLogisticsIssue({
    required String organizationId,
    required String shipmentId,
    required String logisticsIssueId,
    required String status,
    String? resolutionNote,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'resolveLogisticsIssue',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'shipmentId': shipmentId,
        'logisticsIssueId': logisticsIssueId,
        'status': status,
        'resolutionNote': resolutionNote,
      },
    );
  }
}
