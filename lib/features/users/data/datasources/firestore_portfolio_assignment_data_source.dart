import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../dtos/portfolio_assignment_dto.dart';
import 'portfolio_assignment_data_source.dart';

@LazySingleton(as: PortfolioAssignmentDataSource)
final class FirestorePortfolioAssignmentDataSource
    implements PortfolioAssignmentDataSource {
  FirestorePortfolioAssignmentDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<PortfolioAssignmentDto>(
        firestore: firestore,
        collectionName: 'portfolioAssignments',
        converter: FirestoreConverter<PortfolioAssignmentDto>(
          fromJson: (data, id) => PortfolioAssignmentDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<PortfolioAssignmentDto> _collection;

  @override
  Future<PortfolioAssignmentDto> create(PortfolioAssignmentDto dto) async {
    await _collection.set(
      organizationId: dto.organizationId,
      id: dto.id,
      value: dto,
    );
    return dto;
  }

  @override
  Future<List<PortfolioAssignmentDto>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'active')
          .where('deletedAt', isNull: true)
          .orderBy('updatedAt', descending: true),
    );
    return page.items;
  }

  @override
  Future<List<PortfolioAssignmentDto>> listActiveByUser({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 500,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .where('deletedAt', isNull: true)
          .orderBy('updatedAt', descending: true),
    );
    return page.items;
  }

  @override
  Future<PortfolioAssignmentDto?> findActiveCustomerAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 1,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('scopeType', isEqualTo: 'customer')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'active')
          .where('deletedAt', isNull: true),
    );
    return page.items.isEmpty ? null : page.items.first;
  }

  @override
  Future<PortfolioAssignmentDto> endAssignment({
    required String organizationId,
    required String id,
    required String status,
    required DateTime endedAt,
    required String endedBy,
  }) async {
    await _collection.update(
      organizationId: organizationId,
      id: id,
      data: <String, Object?>{
        'status': status,
        'endedAt': Timestamp.fromDate(endedAt),
        'endedBy': endedBy,
        'updatedAt': Timestamp.fromDate(endedAt),
        'updatedBy': endedBy,
        'version': FieldValue.increment(1),
      },
    );

    final updated = await _collection.getById(
      organizationId: organizationId,
      id: id,
    );
    if (updated == null) {
      throw const NotFoundException(
        'Portfolio assignment not found after ending.',
        code: 'portfolio_assignment_not_found_after_end',
      );
    }
    return updated;
  }
}
