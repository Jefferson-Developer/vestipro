import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/customer_import_template.dart';
import '../../domain/repositories/customer_import_template_repository.dart';
import '../datasources/customer_import_template_data_source.dart';
import '../mappers/customer_import_template_mapper.dart';

@LazySingleton(as: CustomerImportTemplateRepository)
final class CustomerImportTemplateRepositoryImpl
    implements CustomerImportTemplateRepository {
  const CustomerImportTemplateRepositoryImpl(this._dataSource, this._mapper);

  final CustomerImportTemplateDataSource _dataSource;
  final CustomerImportTemplateMapper _mapper;

  @override
  Future<AppResult<List<CustomerImportTemplate>>> listByOrganization({
    required String organizationId,
  }) async {
    try {
      final dtos = await _dataSource.listByOrganization(
        organizationId: organizationId,
      );
      return AppSuccess<List<CustomerImportTemplate>>(
        dtos.map(_mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<CustomerImportTemplate>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<CustomerImportTemplate>>(
        UnexpectedFailure(
          'Unexpected error listing customer import templates.',
          code: 'customer_import_template_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CustomerImportTemplate>> save({
    required CustomerImportTemplate template,
  }) async {
    try {
      await _dataSource.save(_mapper.toDto(template));
      return AppSuccess<CustomerImportTemplate>(template);
    } on AppException catch (exception) {
      return AppFailure<CustomerImportTemplate>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<CustomerImportTemplate>(
        UnexpectedFailure(
          'Unexpected error saving customer import template.',
          code: 'customer_import_template_save_unexpected',
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
          'Unexpected error deleting customer import template.',
          code: 'customer_import_template_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
