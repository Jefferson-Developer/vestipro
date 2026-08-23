import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/accepted_invite.dart';
import '../../domain/entities/invite_preview.dart';
import '../../domain/value_objects/invite_acceptance_outcome.dart';
import '../dtos/accepted_invite_dto.dart';
import '../dtos/invite_preview_dto.dart';
import 'invite_mapper.dart';

/// Maps the token-driven invite acceptance DTOs (TASK-040) into their domain
/// entities. Reuses [InviteMapper.roleNameToEntity] for `roleName` parsing
/// instead of duplicating the same lookup — the two mappers cover different
/// entities but the exact same [SystemRoleName] encoding.
@lazySingleton
final class InviteAcceptanceMapper {
  const InviteAcceptanceMapper(this._inviteMapper);

  final InviteMapper _inviteMapper;

  InvitePreview toPreviewEntity(InvitePreviewDto dto) {
    final outcome = inviteAcceptanceOutcomeFromCode(dto.outcome);
    if (outcome == null) {
      throw ValidationException(
        'Invalid invite validation outcome.',
        code: 'invalid_invite_validation_outcome',
        cause: dto.outcome,
      );
    }

    return InvitePreview(
      outcome: outcome,
      organizationId: dto.organizationId,
      organizationName: dto.organizationName,
      email: dto.email,
      roleName: dto.roleName == null
          ? null
          : _inviteMapper.roleNameToEntity(dto.roleName!),
    );
  }

  AcceptedInvite toAcceptedEntity(AcceptedInviteDto dto) {
    return AcceptedInvite(
      organizationId: dto.organizationId,
      organizationName: dto.organizationName,
      roleName: _inviteMapper.roleNameToEntity(dto.roleName),
    );
  }
}
