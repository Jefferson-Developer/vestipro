import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/collection.dart';
import '../repositories/collection_repository.dart';

/// Lists every non-deleted `Collection` of an Organization (TASK-066),
/// active or closed — the same data the Collection management screen and,
/// later, the catalog filter (EPIC-10) both read, avoiding a second source
/// of truth for the taxonomy.
@injectable
final class ListCollectionsUseCase {
  ListCollectionsUseCase(this._repository);

  final CollectionRepository _repository;

  Future<AppResult<List<Collection>>> call(String organizationId) {
    return _repository.listByOrganization(organizationId.trim());
  }
}
