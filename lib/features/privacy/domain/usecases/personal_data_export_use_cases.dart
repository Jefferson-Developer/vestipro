import '../../../../core/utils/utils.dart';
import '../entities/personal_data_export.dart';
import '../repositories/personal_data_export_repository.dart';

final class RequestPersonalDataExport {
  const RequestPersonalDataExport(this._repository);
  final PersonalDataExportRepository _repository;

  Future<AppResult<String>> call({required String organizationId}) =>
      _repository.requestExport(organizationId: organizationId);
}

final class GetPersonalDataExportDownload {
  const GetPersonalDataExportDownload(this._repository);
  final PersonalDataExportRepository _repository;

  Future<AppResult<PersonalDataExportDownload>> call({
    required String exportId,
  }) => _repository.createDownloadLink(exportId: exportId);
}
