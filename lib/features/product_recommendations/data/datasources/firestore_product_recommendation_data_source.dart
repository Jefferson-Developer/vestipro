import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/product_recommendation_dto.dart';
import 'product_recommendation_data_source.dart';

@LazySingleton(as: ProductRecommendationDataSource)
final class FirestoreProductRecommendationDataSource
    implements ProductRecommendationDataSource {
  FirestoreProductRecommendationDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<ProductRecommendationDto>(
        firestore: firestore,
        collectionName: 'productRecommendations',
        converter: FirestoreConverter<ProductRecommendationDto>(
          fromJson: (data, id) =>
              ProductRecommendationDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ProductRecommendationDto> _collection;

  @override
  Future<ProductRecommendationDto?> getRecommendation({
    required String organizationId,
    required String companyId,
    required String scopeType,
    required String scopeId,
  }) {
    return _collection.getById(
      organizationId: organizationId,
      id: productRecommendationDocumentId(companyId, scopeType, scopeId),
    );
  }
}
