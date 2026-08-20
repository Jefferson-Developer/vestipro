import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/entities/about_app.dart';
import '../../domain/entities/about_app_data_origin.dart';
import '../../domain/entities/about_app_note.dart';
import '../../domain/entities/about_app_notes_page.dart';
import '../../domain/usecases/get_about_app_use_case.dart';
import '../../domain/usecases/search_about_app_notes_use_case.dart';
import '../../domain/usecases/submit_about_app_diagnostics_use_case.dart';
import 'about_app_event.dart';
import 'about_app_state.dart';

@injectable
final class AboutAppBloc extends Bloc<AboutAppEvent, AboutAppState> {
  AboutAppBloc({
    required this.getAboutApp,
    required this.searchNotes,
    required this.submitDiagnostics,
    @ignoreParam this.pageSize = 2,
  }) : super(const AboutAppState.initial()) {
    on<AboutAppStarted>(_onStarted, transformer: droppable());
    on<AboutAppSearchQueryChanged>(
      _onSearchQueryChanged,
      transformer: restartable(),
    );
    on<AboutAppNextPageRequested>(
      _onNextPageRequested,
      transformer: droppable(),
    );
    on<AboutAppDiagnosticsSubmitted>(
      _onDiagnosticsSubmitted,
      transformer: sequential(),
    );
  }

  final GetAboutAppUseCase getAboutApp;
  final SearchAboutAppNotesUseCase searchNotes;
  final SubmitAboutAppDiagnosticsUseCase submitDiagnostics;
  final int pageSize;

  Future<void> _onStarted(
    AboutAppStarted event,
    Emitter<AboutAppState> emit,
  ) async {
    final previousAboutApp = _aboutAppOf(state);
    final previousNotes = _notesOf(state);
    final previousQuery = _queryOf(state);
    final previousPage = _pageOf(state);
    final previousHasMore = _hasMoreOf(state);
    final previousDataOrigin = _dataOriginOf(state);

    emit(
      AboutAppState.loading(
        aboutApp: previousAboutApp,
        notes: previousNotes,
        query: previousQuery,
        page: previousPage,
        hasMore: previousHasMore,
        dataOrigin: previousDataOrigin,
      ),
    );

    final aboutResult = await getAboutApp();
    if (emit.isDone) {
      return;
    }

    switch (aboutResult) {
      case AppSuccess<AboutApp>(value: final aboutApp):
        await _loadFirstNotesPage(
          emit: emit,
          aboutApp: aboutApp,
          query: '',
          previousNotes: previousNotes,
          previousPage: previousPage,
          previousHasMore: previousHasMore,
          previousDataOrigin: previousDataOrigin,
        );
      case AppFailure<AboutApp>(failure: final failure):
        emit(
          AboutAppState.failure(
            failure: failure,
            aboutApp: previousAboutApp,
            notes: previousNotes,
            query: previousQuery,
            page: previousPage,
            hasMore: previousHasMore,
            dataOrigin: previousDataOrigin,
          ),
        );
    }
  }

  Future<void> _onSearchQueryChanged(
    AboutAppSearchQueryChanged event,
    Emitter<AboutAppState> emit,
  ) async {
    final aboutApp = _aboutAppOf(state);
    if (aboutApp == null) {
      return;
    }

    final query = event.query.trim();
    final previousNotes = _notesOf(state);
    final previousPage = _pageOf(state);
    final previousHasMore = _hasMoreOf(state);
    final dataOrigin = _dataOriginOf(state);
    emit(
      AboutAppState.ready(
        aboutApp: aboutApp,
        notes: const <AboutAppNote>[],
        page: 0,
        hasMore: true,
        query: query,
        dataOrigin: dataOrigin,
      ),
    );

    await _loadFirstNotesPage(
      emit: emit,
      aboutApp: aboutApp,
      query: query,
      previousNotes: previousNotes,
      previousPage: previousPage,
      previousHasMore: previousHasMore,
      previousDataOrigin: dataOrigin,
    );
  }

  Future<void> _onNextPageRequested(
    AboutAppNextPageRequested event,
    Emitter<AboutAppState> emit,
  ) async {
    final current = state;
    if (current is! AboutAppReady ||
        current.isLoadingNextPage ||
        !current.hasMore) {
      return;
    }

    emit(current.copyWith(isLoadingNextPage: true));

    final result = await searchNotes(
      query: current.query,
      page: current.page + 1,
      pageSize: pageSize,
    );
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<AboutAppNotesPage>(value: final page):
        emit(
          current.copyWith(
            notes: <AboutAppNote>[...current.notes, ...page.items],
            page: page.page,
            hasMore: page.hasMore,
            dataOrigin: page.dataOrigin,
            isLoadingNextPage: false,
          ),
        );
      case AppFailure<AboutAppNotesPage>(failure: final failure):
        emit(
          AboutAppState.failure(
            failure: failure,
            aboutApp: current.aboutApp,
            notes: current.notes,
            query: current.query,
            page: current.page,
            hasMore: current.hasMore,
            dataOrigin: current.dataOrigin,
          ),
        );
    }
  }

  Future<void> _onDiagnosticsSubmitted(
    AboutAppDiagnosticsSubmitted event,
    Emitter<AboutAppState> emit,
  ) async {
    final current = state;
    if (current is! AboutAppReady ||
        current.submissionStatus == AboutAppSubmissionStatus.submitting) {
      return;
    }

    emit(
      current.copyWith(
        submissionStatus: AboutAppSubmissionStatus.submitting,
        submissionFailure: null,
      ),
    );

    final result = await submitDiagnostics();
    if (emit.isDone) {
      return;
    }

    switch (result) {
      case AppSuccess<void>():
        emit(
          current.copyWith(
            submissionStatus: AboutAppSubmissionStatus.submitted,
            submissionFailure: null,
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(
          current.copyWith(
            submissionStatus: AboutAppSubmissionStatus.failure,
            submissionFailure: failure,
          ),
        );
    }
  }

  Future<void> _loadFirstNotesPage({
    required Emitter<AboutAppState> emit,
    required AboutApp aboutApp,
    required String query,
    required List<AboutAppNote> previousNotes,
    required int previousPage,
    required bool previousHasMore,
    required AboutAppDataOrigin previousDataOrigin,
  }) async {
    final notesResult = await searchNotes(
      query: query,
      page: 1,
      pageSize: pageSize,
    );
    if (emit.isDone) {
      return;
    }

    switch (notesResult) {
      case AppSuccess<AboutAppNotesPage>(value: final page):
        emit(
          AboutAppState.ready(
            aboutApp: aboutApp,
            notes: page.items,
            page: page.page,
            hasMore: page.hasMore,
            query: query,
            dataOrigin: page.dataOrigin,
          ),
        );
      case AppFailure<AboutAppNotesPage>(failure: final failure):
        emit(
          AboutAppState.failure(
            failure: failure,
            aboutApp: aboutApp,
            notes: previousNotes,
            query: query,
            page: previousPage,
            hasMore: previousHasMore,
            dataOrigin: previousDataOrigin,
          ),
        );
    }
  }

  AboutApp? _aboutAppOf(AboutAppState state) {
    return switch (state) {
      AboutAppInitial() => null,
      AboutAppLoading(aboutApp: final aboutApp) => aboutApp,
      AboutAppReady(aboutApp: final aboutApp) => aboutApp,
      AboutAppFailure(aboutApp: final aboutApp) => aboutApp,
    };
  }

  List<AboutAppNote> _notesOf(AboutAppState state) {
    return switch (state) {
      AboutAppInitial() => const <AboutAppNote>[],
      AboutAppLoading(notes: final notes) => notes,
      AboutAppReady(notes: final notes) => notes,
      AboutAppFailure(notes: final notes) => notes,
    };
  }

  String _queryOf(AboutAppState state) {
    return switch (state) {
      AboutAppInitial() => '',
      AboutAppLoading(query: final query) => query,
      AboutAppReady(query: final query) => query,
      AboutAppFailure(query: final query) => query,
    };
  }

  int _pageOf(AboutAppState state) {
    return switch (state) {
      AboutAppInitial() => 0,
      AboutAppLoading(page: final page) => page,
      AboutAppReady(page: final page) => page,
      AboutAppFailure(page: final page) => page,
    };
  }

  bool _hasMoreOf(AboutAppState state) {
    return switch (state) {
      AboutAppInitial() => true,
      AboutAppLoading(hasMore: final hasMore) => hasMore,
      AboutAppReady(hasMore: final hasMore) => hasMore,
      AboutAppFailure(hasMore: final hasMore) => hasMore,
    };
  }

  AboutAppDataOrigin _dataOriginOf(AboutAppState state) {
    return switch (state) {
      AboutAppInitial(dataOrigin: final dataOrigin) => dataOrigin,
      AboutAppLoading(dataOrigin: final dataOrigin) => dataOrigin,
      AboutAppReady(dataOrigin: final dataOrigin) => dataOrigin,
      AboutAppFailure(dataOrigin: final dataOrigin) => dataOrigin,
    };
  }
}
