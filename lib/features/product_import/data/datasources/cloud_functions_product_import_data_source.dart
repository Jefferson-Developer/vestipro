import 'package:injectable/injectable.dart';

import '../../../../core/functions/functions.dart';
import 'product_import_functions_data_source.dart';

@LazySingleton(as: ProductImportFunctionsDataSource)
final class CloudFunctionsProductImportDataSource
    implements ProductImportFunctionsDataSource {
  const CloudFunctionsProductImportDataSource(this._functions);

  final CloudFunctionsService _functions;

  @override
  Future<String> startJob({
    required String organizationId,
    required String companyId,
    required String fileName,
    required String storagePath,
    String? imagesFolderPath,
    required bool hasHeaderRow,
    required Map<String, int> columnByField,
    required String sizeGridTemplateId,
    required Map<String, String> categoryIdByName,
    required Map<String, String> collectionIdByName,
    required Map<String, String> colorIdByName,
    required Map<String, String> sizeIdByLabel,
    required bool createMissingCategories,
    required bool createMissingCollections,
    String? templateId,
  }) async {
    final response = await _functions.call<Map<String, dynamic>>(
      'startProductImportJob',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'companyId': companyId,
        'fileName': fileName,
        'storagePath': storagePath,
        if (imagesFolderPath != null) 'imagesFolderPath': imagesFolderPath,
        'mapping': <String, dynamic>{
          'hasHeaderRow': hasHeaderRow,
          'columnByField': columnByField,
          'sizeGridTemplateId': sizeGridTemplateId,
        },
        'lookup': <String, dynamic>{
          'categoryIdByName': categoryIdByName,
          'collectionIdByName': collectionIdByName,
          'colorIdByName': colorIdByName,
          'sizeIdByLabel': sizeIdByLabel,
        },
        'createMissingCategories': createMissingCategories,
        'createMissingCollections': createMissingCollections,
        if (templateId != null) 'templateId': templateId,
      },
      requireAuth: true,
    );
    return response['jobId'] as String;
  }
}
