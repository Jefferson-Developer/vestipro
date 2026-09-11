import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import '../dtos/credit_check_result_dto.dart';
import 'credit_write_data_source.dart';

/// [CreditWriteDataSource] backed by [CloudFunctionsService] (TASK-212) —
/// every mutation/preview goes through the `credit` callables
/// (`validateOrderCredit`, `updateCreditProfile`, `grantCreditOverride`),
/// never a direct Firestore write, same contract
/// `CloudFunctionsBuyerCollaborationWriteDataSource` (TASK-211) already
/// follows.
@LazySingleton(as: CreditWriteDataSource)
final class CloudFunctionsCreditWriteDataSource
    implements CreditWriteDataSource {
  const CloudFunctionsCreditWriteDataSource(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<CreditCheckResultDto> validateOrderCredit({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double orderTotal,
  }) async {
    final json = await _functions.call<Map<String, dynamic>>(
      'validateOrderCredit',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerId': customerId,
        'orderTotal': orderTotal,
      },
    );
    return CreditCheckResultDto.fromJson(json);
  }

  @override
  Future<void> updateProfile({
    required String organizationId,
    required String companyId,
    required String customerId,
    required double creditLimit,
    required double openBalance,
    required double overdueBalance,
    required String blockPolicy,
    double? financialScore,
    required String dataSource,
    required bool manualBlockActive,
    String? manualBlockReason,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'updateCreditProfile',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerId': customerId,
        'creditLimit': creditLimit,
        'openBalance': openBalance,
        'overdueBalance': overdueBalance,
        'blockPolicy': blockPolicy,
        'financialScore': financialScore,
        'dataSource': dataSource,
        'manualBlockActive': manualBlockActive,
        'manualBlockReason': manualBlockReason,
      },
    );
  }

  @override
  Future<void> grantOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String reason,
    required String expiresAt,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'grantCreditOverride',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerId': customerId,
        'action': 'grant',
        'reason': reason,
        'expiresAt': expiresAt,
      },
    );
  }

  @override
  Future<void> revokeOverride({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) {
    return _functions.call<Map<String, dynamic>>(
      'grantCreditOverride',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'customerId': customerId,
        'action': 'revoke',
      },
    );
  }
}
