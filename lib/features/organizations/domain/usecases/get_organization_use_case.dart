import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/organization.dart';
import '../repositories/organization_repository.dart';

/// Reads a single [Organization] by its immutable [id].
@injectable
final class GetOrganizationUseCase {
  const GetOrganizationUseCase(this._repository);

  final OrganizationRepository _repository;

  Future<AppResult<Organization>> call(String id) {
    if (id.trim().isEmpty) {
      return Future<AppResult<Organization>>.value(
        AppFailure<Organization>(
          const ValidationFailure(
            'Organization id is required.',
            code: 'invalid_organization_id',
          ),
        ),
      );
    }

    return _repository.getById(id.trim());
  }
}
