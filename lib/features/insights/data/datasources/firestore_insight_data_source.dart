import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/insight_dto.dart';
import 'insight_data_source.dart';

@LazySingleton(as: InsightDataSource)
final class FirestoreInsightDataSource implements InsightDataSource {
  FirestoreInsightDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<InsightDto>(
        firestore: firestore,
        collectionName: 'insights',
        converter: FirestoreConverter<InsightDto>(
          fromJson: (data, id) => InsightDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<InsightDto> _collection;

  @override
  Future<void> saveAll({
    required String organizationId,
    required List<InsightDto> insights,
  }) async {
    for (final insight in insights) {
      await _collection.set(
        organizationId: organizationId,
        id: insight.id,
        value: insight,
        merge: true,
      );
    }
  }

  @override
  Future<List<InsightDto>> listPageByRecipient({
    required String organizationId,
    required String recipientUserId,
    int limit = 25,
    DateTime? before,
    String? type,
    String? status,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) {
        var scoped = query
            .where('recipientUserId', isEqualTo: recipientUserId)
            .orderBy('generatedAt', descending: true);
        if (type != null && type.isNotEmpty) {
          scoped = scoped.where('type', isEqualTo: type);
        }
        if (status != null && status.isNotEmpty) {
          scoped = scoped.where('status', isEqualTo: status);
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
