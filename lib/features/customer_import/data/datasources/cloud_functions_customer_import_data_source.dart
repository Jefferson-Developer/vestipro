import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import 'customer_import_functions_data_source.dart';

@LazySingleton(as: CustomerImportFunctionsDataSource)
final class CloudFunctionsCustomerImportDataSource
    implements CustomerImportFunctionsDataSource {
  const CloudFunctionsCustomerImportDataSource(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<String> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required String storagePath,
    required bool hasHeaderRow,
    required Map<String, int> columnByField,
    String? templateId,
  }) async {
    final response = await _functions.call<Map<String, dynamic>>(
      'startCustomerImportJob',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'fileName': fileName,
        'storagePath': storagePath,
        'mapping': <String, dynamic>{
          'hasHeaderRow': hasHeaderRow,
          'columnByField': columnByField,
        },
        if (templateId != null) 'templateId': templateId,
      },
      requireAuth: true,
    );
    return response['jobId'] as String;
  }

  @override
  Future<void> resolveDuplicateRow({
    required String organizationId,
    required String jobId,
    required int rowNumber,
    required String resolution,
  }) {
    return _functions.call<void>(
      'resolveCustomerImportDuplicateRow',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'jobId': jobId,
        'rowNumber': rowNumber,
        'resolution': resolution,
      },
      requireAuth: true,
    );
  }
}
