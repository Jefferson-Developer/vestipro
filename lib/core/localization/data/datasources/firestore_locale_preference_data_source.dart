import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../database/database.dart';
import '../dtos/locale_preference_dto.dart';
import 'locale_preference_data_source.dart';

/// Firestore-backed [LocalePreferenceDataSource] for the
/// `organizations/{organizationId}/localePreferences` subcollection
/// (TASK-174), one document per user keyed by `userId` — same
/// `FirestoreCollectionDataSource` composition as
/// `FirestoreCommunicationPreferencesDataSource`, so every write stays
/// scoped by `organizationId` by construction.
@LazySingleton(as: LocalePreferenceDataSource)
final class FirestoreLocalePreferenceDataSource
    implements LocalePreferenceDataSource {
  FirestoreLocalePreferenceDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<LocalePreferenceDto>(
        firestore: firestore,
        collectionName: 'localePreferences',
        converter: FirestoreConverter<LocalePreferenceDto>(
          fromJson: (data, id) => LocalePreferenceDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<LocalePreferenceDto> _collection;

  @override
  Future<void> upsert(LocalePreferenceDto dto) {
    return _collection.set(
      organizationId: dto.organizationId,
      id: dto.userId,
      value: dto,
    );
  }
}
