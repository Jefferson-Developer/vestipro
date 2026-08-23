import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../entities/issued_invite.dart';
import '../repositories/invite_repository.dart';
import '../validators/invite_form_validators.dart';

/// Issues a new pending invite for [email] to join [organizationId] as
/// [roleName] (TASK-039). Validates the payload client-side (organizationId
/// present, e-mail plausible) before ever reaching [InviteRepository.create]
/// — the real authorization/role-hierarchy decision is always
/// [InviteRepository.create]'s (ultimately `createInvite`'s) responsibility,
/// never this use case's.
@injectable
final class CreateInviteUseCase {
  const CreateInviteUseCase(this._repository);

  final InviteRepository _repository;

  Future<AppResult<IssuedInvite>> call({
    required String organizationId,
    required String email,
    required SystemRoleName roleName,
    String? message,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final emailError = validateInviteEmail(email);

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (emailError != null) {
      fieldErrors['email'] = emailError;
    }

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<IssuedInvite>>.value(
        AppFailure<IssuedInvite>(
          ValidationFailure(
            'Invalid invite payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_create_invite_payload',
          ),
        ),
      );
    }

    final trimmedMessage = message?.trim();

    return _repository.create(
      organizationId: trimmedOrganizationId,
      email: email.trim(),
      roleName: roleName,
      message: trimmedMessage == null || trimmedMessage.isEmpty
          ? null
          : trimmedMessage,
    );
  }
}
