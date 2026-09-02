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

  /// Firestore's `whereIn` accepts at most 30 values, so a manager's team
  /// larger than that is split into chunks queried independently and merged
  /// in memory, sorted back by `generatedAt` descending. This is TASK-132's
  /// interim, client-composed answer for a scoped, paginated list — the
  /// dedicated server-side aggregation layer TASK-133 introduces is the
  /// long-term fix for organizations whose teams routinely exceed 30
  /// members.
  static const _maxWhereInSize = 30;

  @override
  Future<List<InsightDto>> listPageByVisibility({
    required String organizationId,
    required Set<String>? recipientUserIds,
    int limit = 25,
    DateTime? before,
    String? type,
  }) async {
    if (recipientUserIds != null && recipientUserIds.isEmpty) {
      return const <InsightDto>[];
    }

    Query<InsightDto> applyCommonFilters(Query<InsightDto> query) {
      var scoped = query.orderBy('generatedAt', descending: true);
      if (type != null && type.isNotEmpty) {
        scoped = scoped.where('type', isEqualTo: type);
      }
      if (before != null) {
        scoped = scoped.where(
          'generatedAt',
          isLessThan: Timestamp.fromDate(before),
        );
      }
      return scoped;
    }

    if (recipientUserIds == null) {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: limit,
        queryBuilder: applyCommonFilters,
      );
      return page.items;
    }

    final ids = recipientUserIds.toList(growable: false);
    final chunks = <List<String>>[
      for (var start = 0; start < ids.length; start += _maxWhereInSize)
        ids.sublist(
          start,
          start + _maxWhereInSize > ids.length
              ? ids.length
              : start + _maxWhereInSize,
        ),
    ];

    if (chunks.length == 1) {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: limit,
        queryBuilder: (query) => applyCommonFilters(
          query.where('recipientUserId', whereIn: chunks.first),
        ),
      );
      return page.items;
    }

    final merged = <InsightDto>[];
    for (final chunk in chunks) {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: limit,
        queryBuilder: (query) =>
            applyCommonFilters(query.where('recipientUserId', whereIn: chunk)),
      );
      merged.addAll(page.items);
    }
    merged.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return merged.take(limit).toList(growable: false);
  }

  @override
  Future<void> updateStatus({
    required String organizationId,
    required String insightId,
    required String status,
  }) {
    return _collection.update(
      organizationId: organizationId,
      id: insightId,
      data: <String, Object?>{'status': status},
    );
  }
}
