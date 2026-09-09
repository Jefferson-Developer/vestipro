import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_recommendation.dart';
import '../../domain/repositories/product_recommendation_repository.dart';
import '../../domain/value_objects/product_recommendation_scope_type.dart';
import '../datasources/product_recommendation_data_source.dart';
import '../mappers/product_recommendation_mapper.dart';

/// Read-only Firestore-backed [ProductRecommendationRepository] (TASK-190,
/// EPIC-28) — already scoped/RBAC'd by `firestore.rules`, same
/// "Firestore-only repository" shape `DemandForecastRepositoryImpl`
/// (TASK-185) already established, since a `ProductRecommendation` is never
/// mutated by a client.
@LazySingleton(as: ProductRecommendationRepository)
final class ProductRecommendationRepositoryImpl
    implements ProductRecommendationRepository {
  const ProductRecommendationRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final ProductRecommendationDataSource dataSource;
  final ProductRecommendationMapper mapper;

  @override
  Future<AppResult<ProductRecommendation?>> getRecommendation({
    required String organizationId,
    required String companyId,
    required ProductRecommendationScopeType scopeType,
    required String scopeId,
  }) async {
    try {
      final dto = await dataSource.getRecommendation(
        organizationId: organizationId,
        companyId: companyId,
        scopeType: scopeType.code,
        scopeId: scopeId,
      );
      return AppSuccess<ProductRecommendation?>(
        dto == null ? null : mapper.toEntity(dto),
      );
    } on AppException catch (exception) {
      return AppFailure<ProductRecommendation?>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<ProductRecommendation?>(
        UnexpectedFailure(
          'Unexpected error loading the product recommendation.',
          code: 'product_recommendation_load_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
