import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../dtos/organization_dto.dart';
import '../dtos/organization_settings_dto.dart';
import 'organization_data_source.dart';

/// [OrganizationDataSource] for the root `organizations` collection
/// (TASK-026/TASK-037).
///
/// [getById]/[updateSettings] read/write `organizations/{id}` directly
/// through the Firestore SDK, like every other tenant-scoped datasource in
/// this codebase — deliberately not built on [FirestoreCollectionDataSource]:
/// that helper always scopes reads/writes under
/// `organizations/{organizationId}/{collectionName}`, but an Organization
/// document *is* the tenant root, not one of its subcollections.
///
/// [create] is the one exception: TASK-037 moved Organization creation to
/// the `createOrganization` callable Cloud Function
/// (`functions/src/organizations/create-organization.ts`), which creates
/// the Organization, seeds its 7 system roles and grants the caller the
/// `OWNER` Membership in a single, idempotent, server-side Firestore
/// transaction. The 3 Security Rules "bootstrap windows" that used to let
/// the client write those documents directly (TASK-030) were removed once
/// this Function existed — a direct `organizations` write from the client
/// is denied now, so [create] must never go back to writing to Firestore
/// directly.
@LazySingleton(as: OrganizationDataSource)
final class FirestoreOrganizationDataSource implements OrganizationDataSource {
  const FirestoreOrganizationDataSource(
    this._firestore,
    this._cloudFunctionsService,
  );

  final FirebaseFirestore _firestore;
  final CloudFunctionsService _cloudFunctionsService;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('organizations');

  @override
  Future<OrganizationDto> create(OrganizationDto dto) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'createOrganization',
      data: <String, dynamic>{
        'organizationId': dto.id,
        'name': dto.name,
        'slug': dto.slug,
        'currency': dto.settings.currency,
        'country': dto.settings.country,
        'defaultLanguage': dto.settings.defaultLanguage,
      },
      requireAuth: true,
    );

    return _organizationDtoFromCallableResponse(response);
  }

  /// Parses the `organization` field of `createOrganization`'s response
  /// into an [OrganizationDto].
  ///
  /// Deliberately not [OrganizationDto.fromJson]: that factory expects
  /// Firestore [Timestamp] values (the shape a `cloud_firestore` document
  /// read/write produces), but a callable Cloud Function response is plain
  /// JSON over the wire — dates arrive as ISO-8601 strings
  /// (`DateTime.parse`-able), not [Timestamp]s.
  OrganizationDto _organizationDtoFromCallableResponse(
    Map<String, dynamic> response,
  ) {
    final organizationJson = response['organization'];
    if (organizationJson is! Map) {
      throw const ServerException(
        'Unexpected createOrganization response shape.',
        code: 'invalid_create_organization_response',
      );
    }
    final json = Map<String, dynamic>.from(organizationJson);

    final id = json['id'];
    final name = json['name'];
    final slug = json['slug'];
    final settingsJson = json['settings'];
    final status = json['status'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];

    if (id is! String ||
        name is! String ||
        slug is! String ||
        settingsJson is! Map ||
        status is! String ||
        createdAt is! String ||
        createdBy is! String ||
        updatedAt is! String ||
        updatedBy is! String) {
      throw const ServerException(
        'Unexpected createOrganization response shape.',
        code: 'invalid_create_organization_response',
      );
    }

    final settings = Map<String, dynamic>.from(settingsJson);
    final currency = settings['currency'];
    final country = settings['country'];
    final defaultLanguage = settings['defaultLanguage'];
    if (currency is! String ||
        country is! String ||
        defaultLanguage is! String) {
      throw const ServerException(
        'Unexpected createOrganization response shape.',
        code: 'invalid_create_organization_response',
      );
    }

    return OrganizationDto(
      id: id,
      name: name,
      slug: slug,
      settings: OrganizationSettingsDto(
        currency: currency,
        country: country,
        defaultLanguage: defaultLanguage,
      ),
      status: status,
      createdAt: DateTime.parse(createdAt),
      createdBy: createdBy,
      updatedAt: DateTime.parse(updatedAt),
      updatedBy: updatedBy,
    );
  }

  @override
  Future<OrganizationDto?> getById(String id) async {
    try {
      final snapshot = await _collection.doc(id).get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return OrganizationDto.fromJson(data, id: snapshot.id);
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }

  @override
  Future<OrganizationDto> updateSettings({
    required String id,
    required OrganizationSettingsDto settings,
    required DateTime updatedAt,
    required String updatedBy,
  }) async {
    try {
      final docRef = _collection.doc(id);
      await docRef.update(<String, Object?>{
        'settings': settings.toJson(),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'updatedBy': updatedBy,
      });

      final snapshot = await docRef.get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) {
        throw const NotFoundException(
          'Organization not found after settings update.',
          code: 'organization_not_found_after_update',
        );
      }
      return OrganizationDto.fromJson(data, id: snapshot.id);
    } on FirebaseException catch (exception, stackTrace) {
      throw mapFirestoreExceptionToAppException(exception, stackTrace);
    }
  }
}
