import '../../../../core/utils/utils.dart';
import '../entities/personal_data_export.dart';

abstract interface class PersonalDataExportRepository {
  Stream<AppResult<List<PersonalDataExport>>> watchExports({
    required String organizationId,
    required String userId,
  });

  Future<AppResult<String>> requestExport({required String organizationId});

  Future<AppResult<PersonalDataExportDownload>> createDownloadLink({
    required String exportId,
  });
}
