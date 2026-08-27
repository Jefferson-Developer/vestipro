import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/warehouse_dto.dart';
import 'warehouse_remote_data_source.dart';

@LazySingleton(as: WarehouseRemoteDataSource)
final class FirestoreWarehouseDataSource implements WarehouseRemoteDataSource {
  FirestoreWarehouseDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<WarehouseDto>(
        firestore: firestore,
        collectionName: 'warehouses',
        converter: FirestoreConverter<WarehouseDto>(
          fromJson: (data, id) => WarehouseDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<WarehouseDto> _collection;

  @override
  Future<List<WarehouseDto>> listByCompany({
    required String organizationId,
    required String companyId,
    String? branchId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 200,
      queryBuilder: (query) {
        var scoped = query
            .where('companyId', isEqualTo: companyId)
            .where('deletedAt', isNull: true)
            .orderBy('priority')
            .orderBy('name');
        if (branchId != null && branchId.isNotEmpty) {
          scoped = scoped.where(
            Filter.or(
              Filter('branchId', isEqualTo: branchId),
              Filter('branchId', isNull: true),
            ),
          );
        }
        return scoped;
      },
    );
    return page.items;
  }
}
