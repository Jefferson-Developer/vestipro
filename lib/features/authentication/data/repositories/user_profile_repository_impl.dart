import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_data_source.dart';
import '../mappers/user_profile_mapper.dart';

@LazySingleton(as: UserProfileRepository)
final class UserProfileRepositoryImpl implements UserProfileRepository {
  const UserProfileRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final UserProfileDataSource dataSource;
  final UserProfileMapper mapper;

  @override
  Future<AppResult<void>> createInitialProfile(UserProfile profile) async {
    try {
      await dataSource.createInitialProfile(mapper.toDto(profile));
      return const AppSuccess<void>(null);
    } on AppException catch (exception) {
      return AppFailure<void>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<void>(
        UnexpectedFailure(
          'Unexpected error creating the initial user profile.',
          code: 'user_profile_create_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
