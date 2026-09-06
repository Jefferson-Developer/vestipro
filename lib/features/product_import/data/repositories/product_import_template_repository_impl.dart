import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_import_template.dart';
import '../../domain/repositories/product_import_template_repository.dart';
import '../datasources/product_import_template_data_source.dart';
import '../mappers/product_import_template_mapper.dart';

@LazySingleton(as: ProductImportTemplateRepository)
final class ProductImportTemplateRepositoryImpl
    implements ProductImportTemplateRepository {
  const ProductImportTemplateRepositoryImpl(this._dataSource, this._mapper);

  final ProductImportTemplateDataSource _dataSource;
  final ProductImportTemplateMapper _mapper;

  @override
  Future<AppResult<List<ProductImportTemplate>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final dtos = await _dataSource.listByOrganization(
        organizationId: organizationId,
      );
      return AppSuccess<List<ProductImportTemplate>>(
        dtos.map(_mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<ProductImportTemplate>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<ProductImportTemplate>>(
        UnexpectedFailure(
          'Unexpected error listing product import templates.',
          code: 'product_import_template_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductImportTemplate>> save({
    required ProductImportTemplate template,
  }) async {
    try {
      await _dataSource.save(_mapper.toDto(template));
      return AppSuccess<ProductImportTemplate>(template);
    } on AppException catch (exception) {
      return AppFailure<ProductImportTemplate>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ProductImportTemplate>(
        UnexpectedFailure(
          'Unexpected error saving product import template.',
          code: 'product_import_template_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  }) async {
    try {
      await _dataSource.delete(organizationId: organizationId, id: id);
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error deleting product import template.',
          code: 'product_import_template_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
