import '../dtos/warehouse_dto.dart';

abstract interface class WarehouseRemoteDataSource {
  Future<List<WarehouseDto>> listByCompany({
    required String organizationId,
    required String companyId,
    String? branchId,
  });
}
