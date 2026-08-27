import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/warehouse.dart';
import '../repositories/warehouse_repository.dart';

@injectable
final class GetWarehousesByCompanyUseCase {
  const GetWarehousesByCompanyUseCase(this._repository);

  final WarehouseRepository _repository;

  Future<AppResult<List<Warehouse>>> call({
    required String organizationId,
    required String companyId,
    String? branchId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedCompanyId = companyId.trim();
    final trimmedBranchId = branchId?.trim();
    if (trimmedOrganizationId.isEmpty || trimmedCompanyId.isEmpty) {
      return Future<AppResult<List<Warehouse>>>.value(
        const AppFailure<List<Warehouse>>(
          ValidationFailure(
            'Invalid warehouse lookup payload.',
            fieldErrors: <String, String>{
              'organizationId': 'OrganizationId is required.',
              'companyId': 'CompanyId is required.',
            },
            code: 'invalid_warehouse_lookup_payload',
          ),
        ),
      );
    }

    return _repository.listByCompany(
      organizationId: trimmedOrganizationId,
      companyId: trimmedCompanyId,
      branchId: trimmedBranchId == null || trimmedBranchId.isEmpty
          ? null
          : trimmedBranchId,
    );
  }
}
