import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/season.dart';
import '../repositories/season_repository.dart';

/// Lists every non-deleted `Season` of an Organization (TASK-066), the same
/// vocabulary reused both by the Collection form's season picker and, later,
/// by the catalog filter (EPIC-10).
@injectable
final class ListSeasonsUseCase {
  ListSeasonsUseCase(this._repository);

  final SeasonRepository _repository;

  Future<AppResult<List<Season>>> call(String organizationId) {
    return _repository.listByOrganization(organizationId.trim());
  }
}
