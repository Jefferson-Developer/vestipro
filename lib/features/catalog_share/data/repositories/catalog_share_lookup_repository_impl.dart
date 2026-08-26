import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_share_preview.dart';
import '../../domain/repositories/catalog_share_lookup_repository.dart';
import '../datasources/catalog_share_lookup_data_source.dart';
import '../mappers/catalog_share_mapper.dart';

@LazySingleton(as: CatalogShareLookupRepository)
final class CatalogShareLookupRepositoryImpl
    implements CatalogShareLookupRepository {
  const CatalogShareLookupRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final CatalogShareLookupDataSource dataSource;
  final CatalogShareMapper mapper;

  @override
  Future<AppResult<CatalogSharePreview>> preview({
    required String token,
  }) async {
    try {
      final dto = await dataSource.preview(token: token);
      return AppSuccess<CatalogSharePreview>(mapper.previewToEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<CatalogSharePreview>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<CatalogSharePreview>(
        UnexpectedFailure(
          'Unexpected error previewing catalog share.',
          code: 'catalog_share_preview_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<void> registerOpen({required String token}) {
    // No try/catch needed here: `CloudFunctionsCatalogShareLookupDataSource`
    // already swallows every failure of its own — see that class' doc.
    return dataSource.registerOpen(token: token);
  }
}
