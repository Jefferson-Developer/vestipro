import '../../../../core/utils/utils.dart';
import '../entities/size_grid_template.dart';

abstract interface class SizeGridTemplateRepository {
  Future<AppResult<SizeGridTemplate>> create({
    required SizeGridTemplate template,
  });

  Future<AppResult<SizeGridTemplate>> update({
    required SizeGridTemplate template,
  });

  Future<AppResult<List<SizeGridTemplate>>> listByOrganization(
    String organizationId,
  );

  Future<AppResult<SizeGridTemplate>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<bool>> nameExists({
    required String organizationId,
    required String name,
    String? excludingTemplateId,
  });

  Future<AppResult<bool>> hasPublishedProductsUsingTemplate({
    required String organizationId,
    required String templateId,
  });

  Future<AppResult<bool>> sizeHasGeneratedVariants({
    required String organizationId,
    required String templateId,
    required String sizeId,
  });
}
