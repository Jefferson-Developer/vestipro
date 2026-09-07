import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/replenishment_suggestion_dto.dart';
import 'replenishment_suggestion_data_source.dart';

@LazySingleton(as: ReplenishmentSuggestionDataSource)
final class FirestoreReplenishmentSuggestionDataSource
    implements ReplenishmentSuggestionDataSource {
  FirestoreReplenishmentSuggestionDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<ReplenishmentSuggestionDto>(
        firestore: firestore,
        collectionName: 'replenishmentSuggestions',
        converter: FirestoreConverter<ReplenishmentSuggestionDto>(
          fromJson: (data, id) =>
              ReplenishmentSuggestionDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ReplenishmentSuggestionDto> _collection;

  @override
  Future<List<ReplenishmentSuggestionDto>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    String? status,
    String? warehouseId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) {
        var scoped = query.orderBy('generatedAt', descending: true);
        if (status != null && status.isNotEmpty) {
          scoped = scoped.where('status', isEqualTo: status);
        }
        if (warehouseId != null && warehouseId.isNotEmpty) {
          scoped = scoped.where('warehouseId', isEqualTo: warehouseId);
        }
        if (before != null) {
          scoped = scoped.where(
            'generatedAt',
            isLessThan: Timestamp.fromDate(before),
          );
        }
        return scoped;
      },
    );
    return page.items;
  }
}
