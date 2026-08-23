import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/accepted_invite.dart';
import '../../domain/entities/invite_preview.dart';
import '../../domain/repositories/invite_acceptance_repository.dart';
import '../datasources/invite_acceptance_data_source.dart';
import '../mappers/invite_acceptance_mapper.dart';

@LazySingleton(as: InviteAcceptanceRepository)
final class InviteAcceptanceRepositoryImpl
    implements InviteAcceptanceRepository {
  const InviteAcceptanceRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final InviteAcceptanceDataSource dataSource;
  final InviteAcceptanceMapper mapper;

  @override
  Future<AppResult<InvitePreview>> validate({required String token}) async {
    try {
      final dto = await dataSource.validate(token: token);
      return AppSuccess<InvitePreview>(mapper.toPreviewEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<InvitePreview>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<InvitePreview>(
        UnexpectedFailure(
          'Unexpected error validating invite.',
          code: 'invite_validate_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<AcceptedInvite>> accept({required String token}) async {
    try {
      final dto = await dataSource.accept(token: token);
      return AppSuccess<AcceptedInvite>(mapper.toAcceptedEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<AcceptedInvite>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<AcceptedInvite>(
        UnexpectedFailure(
          'Unexpected error accepting invite.',
          code: 'invite_accept_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
