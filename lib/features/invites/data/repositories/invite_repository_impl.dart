import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/invite.dart';
import '../../domain/entities/issued_invite.dart';
import '../../domain/repositories/invite_repository.dart';
import '../datasources/invite_data_source.dart';
import '../mappers/invite_mapper.dart';

@LazySingleton(as: InviteRepository)
final class InviteRepositoryImpl implements InviteRepository {
  const InviteRepositoryImpl({required this.dataSource, required this.mapper});

  final InviteDataSource dataSource;
  final InviteMapper mapper;

  @override
  Future<AppResult<IssuedInvite>> create({
    required String organizationId,
    required String email,
    required SystemRoleName roleName,
    String? message,
  }) async {
    try {
      final issued = await dataSource.create(
        organizationId: organizationId,
        email: email,
        roleName: mapper.roleNameToDto(roleName),
        message: message,
      );
      return AppSuccess<IssuedInvite>(
        IssuedInvite(
          invite: mapper.toEntity(issued.invite),
          token: issued.token,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<IssuedInvite>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<IssuedInvite>(
        UnexpectedFailure(
          'Unexpected error creating invite.',
          code: 'invite_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Invite>>> listPending(String organizationId) async {
    try {
      final dtos = await dataSource.listPending(organizationId);
      return AppSuccess<List<Invite>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<Invite>>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<List<Invite>>(
        UnexpectedFailure(
          'Unexpected error listing invites.',
          code: 'invite_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<IssuedInvite>> resend({
    required String organizationId,
    required String inviteId,
  }) async {
    try {
      final issued = await dataSource.resend(
        organizationId: organizationId,
        inviteId: inviteId,
      );
      return AppSuccess<IssuedInvite>(
        IssuedInvite(
          invite: mapper.toEntity(issued.invite),
          token: issued.token,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<IssuedInvite>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<IssuedInvite>(
        UnexpectedFailure(
          'Unexpected error resending invite.',
          code: 'invite_resend_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Invite>> revoke({
    required String organizationId,
    required String inviteId,
  }) async {
    try {
      final dto = await dataSource.revoke(
        organizationId: organizationId,
        inviteId: inviteId,
      );
      return AppSuccess<Invite>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Invite>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Invite>(
        UnexpectedFailure(
          'Unexpected error revoking invite.',
          code: 'invite_revoke_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
