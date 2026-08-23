import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../dtos/invite_dto.dart';
import 'invite_data_source.dart';

/// Firestore/Cloud-Functions-backed [InviteDataSource] for the
/// `organizations/{organizationId}/invites` subcollection (TASK-039).
///
/// [listPending] reads Firestore directly through
/// [FirestoreCollectionDataSource], same pattern as every other
/// read-mostly feature datasource (`FirestoreCompanyDataSource`, ...).
/// [create]/[resend]/[revoke] never write to Firestore directly — they call
/// the corresponding callable Cloud Function through
/// [CloudFunctionsService] and parse its JSON response by hand (dates as
/// ISO-8601 strings, never [InviteDto.fromJson]'s [Timestamp] shape), same
/// pattern `FirestoreOrganizationDataSource.create` established for
/// `createOrganization` (TASK-037).
@LazySingleton(as: InviteDataSource)
final class FirestoreInviteDataSource implements InviteDataSource {
  FirestoreInviteDataSource(
    this._cloudFunctionsService,
    FirebaseFirestore firestore,
  ) : _collection = FirestoreCollectionDataSource<InviteDto>(
        firestore: firestore,
        collectionName: 'invites',
        converter: FirestoreConverter<InviteDto>(
          fromJson: (data, id) => InviteDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final CloudFunctionsService _cloudFunctionsService;
  final FirestoreCollectionDataSource<InviteDto> _collection;

  @override
  Future<IssuedInviteDto> create({
    required String organizationId,
    required String email,
    required String roleName,
    String? message,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'createInvite',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'email': email,
        'roleName': roleName,
        'message': ?message,
      },
      requireAuth: true,
    );
    return _issuedInviteFromCallableResponse(response);
  }

  @override
  Future<List<InviteDto>> listPending(String organizationId) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 200,
      queryBuilder: (query) => query
          .where('status', whereIn: <String>['pending', 'expired'])
          .orderBy('createdAt', descending: true),
    );
    return page.items;
  }

  @override
  Future<IssuedInviteDto> resend({
    required String organizationId,
    required String inviteId,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'resendInvite',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'inviteId': inviteId,
      },
      requireAuth: true,
    );
    return _issuedInviteFromCallableResponse(response);
  }

  @override
  Future<InviteDto> revoke({
    required String organizationId,
    required String inviteId,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'revokeInvite',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'inviteId': inviteId,
      },
      requireAuth: true,
    );
    return _inviteDtoFromJson(_requireInviteJson(response));
  }

  Map<String, dynamic> _requireInviteJson(Map<String, dynamic> response) {
    final inviteJson = response['invite'];
    if (inviteJson is! Map) {
      throw const ServerException(
        'Unexpected invite callable response shape.',
        code: 'invalid_invite_callable_response',
      );
    }
    return Map<String, dynamic>.from(inviteJson);
  }

  IssuedInviteDto _issuedInviteFromCallableResponse(
    Map<String, dynamic> response,
  ) {
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ServerException(
        'Unexpected invite callable response shape.',
        code: 'invalid_invite_callable_response',
      );
    }
    return (
      invite: _inviteDtoFromJson(_requireInviteJson(response)),
      token: token,
    );
  }

  /// Parses one `invite` JSON object from a callable response — plain JSON
  /// over the wire, dates as `DateTime.parse`-able ISO-8601 strings, unlike
  /// [InviteDto.fromJson]'s Firestore [Timestamp] shape.
  InviteDto _inviteDtoFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final organizationId = json['organizationId'];
    final email = json['email'];
    final roleName = json['roleName'];
    final status = json['status'];
    final invitedByUserId = json['invitedByUserId'];
    final invitedByName = json['invitedByName'];
    final message = json['message'];
    final expiresAt = json['expiresAt'];
    final createdAt = json['createdAt'];
    final createdBy = json['createdBy'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];

    if (id is! String ||
        organizationId is! String ||
        email is! String ||
        roleName is! String ||
        status is! String ||
        invitedByUserId is! String ||
        invitedByName is! String ||
        (message != null && message is! String) ||
        expiresAt is! String ||
        createdAt is! String ||
        createdBy is! String ||
        updatedAt is! String ||
        updatedBy is! String) {
      throw const ServerException(
        'Unexpected invite callable response shape.',
        code: 'invalid_invite_callable_response',
      );
    }

    return InviteDto(
      id: id,
      organizationId: organizationId,
      email: email,
      roleName: roleName,
      status: status,
      invitedByUserId: invitedByUserId,
      invitedByName: invitedByName,
      message: message as String?,
      expiresAt: DateTime.parse(expiresAt),
      createdAt: DateTime.parse(createdAt),
      createdBy: createdBy,
      updatedAt: DateTime.parse(updatedAt),
      updatedBy: updatedBy,
    );
  }
}
