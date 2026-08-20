import '../dtos/about_app_dto.dart';
import '../dtos/about_app_notes_page_dto.dart';

abstract interface class AboutAppDataSource {
  Future<AboutAppDto> getAboutApp();

  Future<AboutAppNotesPageDto> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  });

  Future<void> submitDiagnostics();
}
