import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/about_app_notes_page.dart';
import '../repositories/about_app_repository.dart';

@injectable
final class SearchAboutAppNotesUseCase {
  const SearchAboutAppNotesUseCase(this._repository);

  final AboutAppRepository _repository;

  Future<AppResult<AboutAppNotesPage>> call({
    required String query,
    required int page,
    required int pageSize,
  }) {
    return _repository.searchArchitectureNotes(
      query: query,
      page: page,
      pageSize: pageSize,
    );
  }
}
