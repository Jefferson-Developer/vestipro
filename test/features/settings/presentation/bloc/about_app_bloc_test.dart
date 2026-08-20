import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/settings/domain/entities/about_app.dart';
import 'package:vestipro/features/settings/domain/entities/about_app_data_origin.dart';
import 'package:vestipro/features/settings/domain/entities/about_app_note.dart';
import 'package:vestipro/features/settings/domain/entities/about_app_notes_page.dart';
import 'package:vestipro/features/settings/domain/repositories/about_app_repository.dart';
import 'package:vestipro/features/settings/domain/usecases/get_about_app_use_case.dart';
import 'package:vestipro/features/settings/domain/usecases/search_about_app_notes_use_case.dart';
import 'package:vestipro/features/settings/domain/usecases/submit_about_app_diagnostics_use_case.dart';
import 'package:vestipro/features/settings/domain/value_objects/app_version.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_bloc.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_event.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_state.dart';

void main() {
  group('AboutAppBloc', () {
    blocTest<AboutAppBloc, AboutAppState>(
      'loads about app and first notes page',
      build: () => _buildBloc(
        repository: _AboutAppRepositoryStub(
          searchResults: <String, AppResult<AboutAppNotesPage>>{
            _searchKey('', 1): AppSuccess<AboutAppNotesPage>(_pageOne),
          },
        ),
      ),
      act: (bloc) => bloc.add(const AboutAppEvent.started()),
      expect: () => <AboutAppState>[
        const AboutAppState.loading(),
        AboutAppState.ready(
          aboutApp: _aboutApp,
          notes: _pageOne.items,
          page: 1,
          hasMore: true,
          query: '',
          dataOrigin: AboutAppDataOrigin.localCache,
        ),
      ],
    );

    blocTest<AboutAppBloc, AboutAppState>(
      'preserves loaded notes when the next page fails',
      build: () => _buildBloc(
        repository: _AboutAppRepositoryStub(
          searchResults: <String, AppResult<AboutAppNotesPage>>{
            _searchKey('', 2): const AppFailure<AboutAppNotesPage>(
              _nextPageFailure,
            ),
          },
        ),
      ),
      seed: () => AboutAppState.ready(
        aboutApp: _aboutApp,
        notes: _pageOne.items,
        page: 1,
        hasMore: true,
        query: '',
        dataOrigin: AboutAppDataOrigin.localCache,
      ),
      act: (bloc) => bloc.add(const AboutAppEvent.nextPageRequested()),
      expect: () => <Matcher>[
        isA<AboutAppReady>().having(
          (state) => state.isLoadingNextPage,
          'isLoadingNextPage',
          isTrue,
        ),
        isA<AboutAppFailure>()
            .having((state) => state.failure, 'failure', _nextPageFailure)
            .having((state) => state.notes, 'notes', _pageOne.items)
            .having((state) => state.page, 'page', 1)
            .having((state) => state.hasMore, 'hasMore', isTrue),
      ],
    );

    blocTest<AboutAppBloc, AboutAppState>(
      'uses restartable search so the latest query wins',
      build: () => _buildBloc(
        repository: _AboutAppRepositoryStub(
          searchDelays: <String, Duration>{
            _searchKey('slow', 1): const Duration(milliseconds: 40),
            _searchKey('fast', 1): const Duration(milliseconds: 1),
          },
          searchResults: <String, AppResult<AboutAppNotesPage>>{
            _searchKey('slow', 1): AppSuccess<AboutAppNotesPage>(
              _pageWithNote('slow', 'Slow result'),
            ),
            _searchKey('fast', 1): AppSuccess<AboutAppNotesPage>(
              _pageWithNote('fast', 'Fast result'),
            ),
          },
        ),
      ),
      seed: () => AboutAppState.ready(
        aboutApp: _aboutApp,
        notes: _pageOne.items,
        page: 1,
        hasMore: true,
        query: '',
        dataOrigin: AboutAppDataOrigin.localCache,
      ),
      act: (bloc) async {
        bloc.add(const AboutAppEvent.searchQueryChanged('slow'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const AboutAppEvent.searchQueryChanged('fast'));
      },
      wait: const Duration(milliseconds: 80),
      expect: () => <Matcher>[
        isA<AboutAppReady>().having((state) => state.query, 'query', 'slow'),
        isA<AboutAppReady>().having((state) => state.query, 'query', 'fast'),
        isA<AboutAppReady>()
            .having((state) => state.query, 'query', 'fast')
            .having(
              (state) => state.notes.single.title,
              'title',
              'Fast result',
            ),
      ],
    );

    blocTest<AboutAppBloc, AboutAppState>(
      'runs diagnostics submissions in sequence',
      build: () => _buildBloc(repository: _AboutAppRepositoryStub()),
      seed: () => AboutAppState.ready(
        aboutApp: _aboutApp,
        notes: _pageOne.items,
        page: 1,
        hasMore: true,
        query: '',
        dataOrigin: AboutAppDataOrigin.localCache,
      ),
      act: (bloc) {
        bloc
          ..add(const AboutAppEvent.diagnosticsSubmitted())
          ..add(const AboutAppEvent.diagnosticsSubmitted());
      },
      expect: () => <Matcher>[
        isA<AboutAppReady>().having(
          (state) => state.submissionStatus,
          'submissionStatus',
          AboutAppSubmissionStatus.submitting,
        ),
        isA<AboutAppReady>().having(
          (state) => state.submissionStatus,
          'submissionStatus',
          AboutAppSubmissionStatus.submitted,
        ),
        isA<AboutAppReady>().having(
          (state) => state.submissionStatus,
          'submissionStatus',
          AboutAppSubmissionStatus.submitting,
        ),
        isA<AboutAppReady>().having(
          (state) => state.submissionStatus,
          'submissionStatus',
          AboutAppSubmissionStatus.submitted,
        ),
      ],
    );
  });
}

AboutAppBloc _buildBloc({required AboutAppRepository repository}) {
  return AboutAppBloc(
    getAboutApp: GetAboutAppUseCase(repository),
    searchNotes: SearchAboutAppNotesUseCase(repository),
    submitDiagnostics: SubmitAboutAppDiagnosticsUseCase(repository),
  );
}

String _searchKey(String query, int page) => '$query::$page';

AboutAppNotesPage _pageWithNote(String id, String title) {
  return AboutAppNotesPage(
    items: <AboutAppNote>[
      AboutAppNote(id: id, title: title, description: '$title description'),
    ],
    page: 1,
    hasMore: false,
    dataOrigin: AboutAppDataOrigin.remoteSynced,
  );
}

final _aboutApp = AboutApp(
  name: 'VestiPro Dev',
  version: const AppVersion(major: 1, minor: 0, patch: 0, buildNumber: 1),
  environmentLabel: 'development',
  updatedAt: DateTime.utc(2026, 8, 20),
);

final _pageOne = AboutAppNotesPage(
  items: const <AboutAppNote>[
    AboutAppNote(
      id: 'states',
      title: 'Estados completos',
      description: 'Cada estado e consistente.',
    ),
    AboutAppNote(
      id: 'events',
      title: 'Eventos por intencao',
      description: 'Cada evento descreve uma intencao.',
    ),
  ],
  page: 1,
  hasMore: true,
  dataOrigin: AboutAppDataOrigin.localCache,
);

const _nextPageFailure = ConnectivityFailure('Offline.');

final class _AboutAppRepositoryStub implements AboutAppRepository {
  _AboutAppRepositoryStub({
    this.searchDelays = const <String, Duration>{},
    this.searchResults = const <String, AppResult<AboutAppNotesPage>>{},
  });

  final Map<String, Duration> searchDelays;
  final Map<String, AppResult<AboutAppNotesPage>> searchResults;

  @override
  Future<AppResult<AboutApp>> getAboutApp() async {
    return AppSuccess<AboutApp>(_aboutApp);
  }

  @override
  Future<AppResult<AboutAppNotesPage>> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final key = _searchKey(query, page);
    final delay = searchDelays[key] ?? Duration.zero;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    return searchResults[key] ?? AppSuccess<AboutAppNotesPage>(_pageOne);
  }

  @override
  Future<AppResult<void>> submitDiagnostics() async {
    return AppSuccess<void>(null);
  }
}
