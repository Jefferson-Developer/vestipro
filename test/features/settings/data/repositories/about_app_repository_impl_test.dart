import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/settings/data/datasources/about_app_data_source.dart';
import 'package:vestipro/features/settings/data/dtos/about_app_dto.dart';
import 'package:vestipro/features/settings/data/dtos/about_app_note_dto.dart';
import 'package:vestipro/features/settings/data/dtos/about_app_notes_page_dto.dart';
import 'package:vestipro/features/settings/data/mappers/about_app_mapper.dart';
import 'package:vestipro/features/settings/data/mappers/about_app_notes_mapper.dart';
import 'package:vestipro/features/settings/data/repositories/about_app_repository_impl.dart';
import 'package:vestipro/features/settings/domain/entities/about_app.dart';
import 'package:vestipro/features/settings/domain/entities/about_app_data_origin.dart';
import 'package:vestipro/features/settings/domain/entities/about_app_notes_page.dart';

class _MockAboutAppDataSource extends Mock implements AboutAppDataSource {}

void main() {
  group('AboutAppRepositoryImpl', () {
    late _MockAboutAppDataSource dataSource;
    late AboutAppRepositoryImpl repository;

    const validDto = AboutAppDto(
      name: 'VestiPro',
      version: '1.2.3+4',
      environmentLabel: 'development',
      updatedAtIso: '2026-08-20T00:00:00.000Z',
    );

    setUp(() {
      dataSource = _MockAboutAppDataSource();
      repository = AboutAppRepositoryImpl(
        dataSource: dataSource,
        mapper: const AboutAppMapper(),
        notesMapper: const AboutAppNotesMapper(),
      );
    });

    group('getAboutApp', () {
      test(
        'returns a success mapping the DTO returned by the datasource to an entity',
        () async {
          when(
            () => dataSource.getAboutApp(),
          ).thenAnswer((_) async => validDto);

          final result = await repository.getAboutApp();

          expect(result, isA<AppSuccess<AboutApp>>());
          final entity = (result as AppSuccess<AboutApp>).value;
          expect(entity.name, 'VestiPro');
          expect(entity.version.displayValue, '1.2.3+4');
          expect(entity.environmentLabel, 'development');
          expect(entity.updatedAt, DateTime.parse('2026-08-20T00:00:00.000Z'));
          verify(() => dataSource.getAboutApp()).called(1);
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(() => dataSource.getAboutApp()).thenThrow(
            const NotFoundException(
              'About app not found.',
              code: 'about_app_not_found',
            ),
          );

          final result = await repository.getAboutApp();

          expect(result, isA<AppFailure<AboutApp>>());
          expect(
            (result as AppFailure<AboutApp>).failure,
            isA<NotFoundFailure>(),
          );
        },
      );

      test(
        'maps a FormatException thrown by the datasource to a ValidationFailure',
        () async {
          when(
            () => dataSource.getAboutApp(),
          ).thenThrow(const FormatException('Malformed payload.'));

          final result = await repository.getAboutApp();

          expect(result, isA<AppFailure<AboutApp>>());
          final failure = (result as AppFailure<AboutApp>).failure;
          expect(failure, isA<ValidationFailure>());
          expect(failure.code, 'invalid_about_app_payload');
        },
      );

      test(
        'maps a generic exception thrown by the datasource to an UnexpectedFailure',
        () async {
          when(() => dataSource.getAboutApp()).thenThrow(StateError('boom'));

          final result = await repository.getAboutApp();

          expect(result, isA<AppFailure<AboutApp>>());
          final failure = (result as AppFailure<AboutApp>).failure;
          expect(failure, isA<UnexpectedFailure>());
          expect(failure.code, 'about_app_unexpected');
        },
      );
    });

    group('searchArchitectureNotes', () {
      const notesDto = AboutAppNotesPageDto(
        items: <AboutAppNoteDto>[
          AboutAppNoteDto(
            id: 'note-1',
            title: 'Clean Architecture',
            description: 'Feature-first layering.',
          ),
        ],
        page: 1,
        hasMore: false,
        dataOrigin: 'remote_synced',
      );

      test(
        'returns a success mapping the DTO returned by the datasource to an entity',
        () async {
          when(
            () => dataSource.searchArchitectureNotes(
              query: 'clean',
              page: 1,
              pageSize: 10,
            ),
          ).thenAnswer((_) async => notesDto);

          final result = await repository.searchArchitectureNotes(
            query: 'clean',
            page: 1,
            pageSize: 10,
          );

          expect(result, isA<AppSuccess<AboutAppNotesPage>>());
          final entity = (result as AppSuccess<AboutAppNotesPage>).value;
          expect(entity.items, hasLength(1));
          expect(entity.dataOrigin, AboutAppDataOrigin.remoteSynced);
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.searchArchitectureNotes(
              query: 'clean',
              page: 1,
              pageSize: 10,
            ),
          ).thenThrow(
            const ServerException('Search unavailable.', statusCode: 500),
          );

          final result = await repository.searchArchitectureNotes(
            query: 'clean',
            page: 1,
            pageSize: 10,
          );

          expect(result, isA<AppFailure<AboutAppNotesPage>>());
          expect(
            (result as AppFailure<AboutAppNotesPage>).failure,
            isA<ServerFailure>(),
          );
        },
      );
    });

    group('submitDiagnostics', () {
      test(
        'returns a success when the datasource submits diagnostics',
        () async {
          when(() => dataSource.submitDiagnostics()).thenAnswer((_) async {});

          final result = await repository.submitDiagnostics();

          expect(result, isA<AppSuccess<void>>());
          verify(() => dataSource.submitDiagnostics()).called(1);
        },
      );

      test(
        'maps an AppException thrown by the datasource to a Failure',
        () async {
          when(
            () => dataSource.submitDiagnostics(),
          ).thenThrow(const NetworkException('No connectivity.'));

          final result = await repository.submitDiagnostics();

          expect(result, isA<AppFailure<void>>());
          expect(
            (result as AppFailure<void>).failure,
            isA<ConnectivityFailure>(),
          );
        },
      );
    });
  });
}
