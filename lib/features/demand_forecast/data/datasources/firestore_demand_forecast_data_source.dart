import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/demand_forecast_dto.dart';
import 'demand_forecast_data_source.dart';

@LazySingleton(as: DemandForecastDataSource)
final class FirestoreDemandForecastDataSource
    implements DemandForecastDataSource {
  FirestoreDemandForecastDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<DemandForecastDto>(
        firestore: firestore,
        collectionName: 'demandForecasts',
        converter: FirestoreConverter<DemandForecastDto>(
          fromJson: (data, id) => DemandForecastDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<DemandForecastDto> _collection;

  @override
  Future<DemandForecastDto?> getLatestForecast({
    required String organizationId,
    required String companyId,
    required String scopeType,
    required String scopeId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 1,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('scopeType', isEqualTo: scopeType)
          .where('scopeId', isEqualTo: scopeId)
          .orderBy('generatedAt', descending: true),
    );
    return page.items.isEmpty ? null : page.items.first;
  }
}
