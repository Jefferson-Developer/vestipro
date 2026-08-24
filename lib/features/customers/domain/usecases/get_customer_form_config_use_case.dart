import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../../organizations/domain/repositories/organization_repository.dart';
import '../entities/customer_form_config.dart';

@injectable
final class GetCustomerFormConfigUseCase {
  const GetCustomerFormConfigUseCase(this._organizationRepository);

  final OrganizationRepository _organizationRepository;

  Future<AppResult<CustomerFormConfig>> call(String organizationId) async {
    final trimmedOrganizationId = organizationId.trim();
    if (trimmedOrganizationId.isEmpty) {
      return const AppFailure<CustomerFormConfig>(
        ValidationFailure(
          'Organization id is required.',
          code: 'invalid_organization_id',
        ),
      );
    }

    final result = await _organizationRepository.getById(trimmedOrganizationId);
    return result.fold(
      onSuccess: (Organization organization) => AppSuccess<CustomerFormConfig>(
        CustomerFormConfig.fromOrganizationSettings(organization.settings),
      ),
      onFailure: (failure) {
        if (failure is NotFoundFailure || failure is ConnectivityFailure) {
          return const AppSuccess<CustomerFormConfig>(CustomerFormConfig());
        }
        return AppFailure<CustomerFormConfig>(failure);
      },
    );
  }
}
