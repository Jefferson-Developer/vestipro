import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/authentication/data/datasources/user_profile_data_source.dart';
import 'package:vestipro/features/authentication/data/mappers/user_profile_mapper.dart';
import 'package:vestipro/features/authentication/data/repositories/user_profile_repository_impl.dart';
import 'package:vestipro/features/authentication/domain/entities/user_profile.dart';

class _MockUserProfileDataSource extends Mock
    implements UserProfileDataSource {}

void main() {
  group('UserProfileRepositoryImpl', () {
    late _MockUserProfileDataSource dataSource;
    late UserProfileRepositoryImpl repository;

    final profile = UserProfile(
      uid: 'user-1',
      name: 'Ana Souza',
      email: 'ana@vestipro.com.br',
      createdAt: DateTime.utc(2026, 8, 23),
      termsVersion: '2026-08-23',
      termsAcceptedAt: DateTime.utc(2026, 8, 23),
    );

    setUpAll(() {
      registerFallbackValue(const UserProfileMapper().toDto(profile));
    });

    setUp(() {
      dataSource = _MockUserProfileDataSource();
      repository = UserProfileRepositoryImpl(
        dataSource: dataSource,
        mapper: const UserProfileMapper(),
      );
    });

    group('createInitialProfile', () {
      test('returns a success when the datasource writes the doc', () async {
        when(
          () => dataSource.createInitialProfile(any()),
        ).thenAnswer((_) async {});

        final result = await repository.createInitialProfile(profile);

        expect(result, isA<AppSuccess<void>>());
      });

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.createInitialProfile(any()),
          ).thenThrow(const NetworkException('No connectivity.'));

          final result = await repository.createInitialProfile(profile);

          expect(result, isA<AppFailure<void>>());
          expect(
            (result as AppFailure<void>).failure,
            isA<ConnectivityFailure>(),
          );
        },
      );

      test(
        'maps a generic exception thrown by the datasource to an UnexpectedFailure',
        () async {
          when(
            () => dataSource.createInitialProfile(any()),
          ).thenThrow(StateError('boom'));

          final result = await repository.createInitialProfile(profile);

          expect(result, isA<AppFailure<void>>());
          final failure = (result as AppFailure<void>).failure;
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.code, 'user_profile_create_unexpected');
        },
      );
    });
  });
}
