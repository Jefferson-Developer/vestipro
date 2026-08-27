import '../../../../core/utils/utils.dart';
import '../entities/warehouse.dart';

abstract interface class WarehouseRepository {
  Future<AppResult<List<Warehouse>>> listByCompany({
    required String organizationId,
    required String companyId,
    String? branchId,
  });

  Future<AppResult<List<Warehouse>>> listActive({
    required String organizationId,
    required String companyId,
    String? branchId,
  });
}
