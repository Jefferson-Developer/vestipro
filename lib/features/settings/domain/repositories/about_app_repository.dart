import '../../../../core/utils/utils.dart';
import '../entities/about_app.dart';
import '../entities/about_app_notes_page.dart';

abstract interface class AboutAppRepository {
  Future<AppResult<AboutApp>> getAboutApp();

  Future<AppResult<AboutAppNotesPage>> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  });

  Future<AppResult<void>> submitDiagnostics();
}
