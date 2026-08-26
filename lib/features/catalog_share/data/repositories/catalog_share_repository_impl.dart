import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_share.dart';
import '../../domain/entities/catalog_share_item.dart';
import '../../domain/entities/issued_catalog_share.dart';
import '../../domain/repositories/catalog_share_repository.dart';
import '../../domain/value_objects/catalog_share_scope.dart';
import '../datasources/catalog_share_data_source.dart';
import '../mappers/catalog_share_mapper.dart';

@LazySingleton(as: CatalogShareRepository)
final class CatalogShareRepositoryImpl implements CatalogShareRepository {
  const CatalogShareRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final CatalogShareDataSource dataSource;
  final CatalogShareMapper mapper;

  @override
  Future<AppResult<IssuedCatalogShare>> create({
    required String organizationId,
    required CatalogShareScope scope,
    required List<CatalogShareItem> items,
    String? collectionId,
    String? collectionName,
    int? expiresInDays,
  }) async {
    try {
      final issued = await dataSource.create(
        organizationId: organizationId,
        scope: mapper.scopeToDto(scope),
        items: items.map(mapper.itemToDto).toList(growable: false),
        collectionId: collectionId,
        collectionName: collectionName,
        expiresInDays: expiresInDays,
      );
      return AppSuccess<IssuedCatalogShare>(
        IssuedCatalogShare(
          share: mapper.toEntity(issued.share),
          token: issued.token,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<IssuedCatalogShare>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<IssuedCatalogShare>(
        UnexpectedFailure(
          'Unexpected error creating catalog share.',
          code: 'catalog_share_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CatalogShare>> revoke({
    required String organizationId,
    required String shareId,
  }) async {
    try {
      final dto = await dataSource.revoke(
        organizationId: organizationId,
        shareId: shareId,
      );
      return AppSuccess<CatalogShare>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<CatalogShare>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<CatalogShare>(
        UnexpectedFailure(
          'Unexpected error revoking catalog share.',
          code: 'catalog_share_revoke_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CatalogShare>> getById({
    required String organizationId,
    required String shareId,
  }) async {
    try {
      final dto = await dataSource.getById(
        organizationId: organizationId,
        shareId: shareId,
      );
      if (dto == null) {
        return AppFailure<CatalogShare>(
          const NotFoundFailure(
            'Compartilhamento não encontrado.',
            code: 'catalog_share_not_found',
          ),
        );
      }
      return AppSuccess<CatalogShare>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<CatalogShare>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<CatalogShare>(
        UnexpectedFailure(
          'Unexpected error reading catalog share.',
          code: 'catalog_share_get_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
