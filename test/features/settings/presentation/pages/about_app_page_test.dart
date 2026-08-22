import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/settings/data/datasources/about_app_data_source.dart';
import 'package:vestipro/features/settings/data/datasources/in_memory_about_app_datasource.dart';
import 'package:vestipro/features/settings/data/dtos/about_app_dto.dart';
import 'package:vestipro/features/settings/data/dtos/about_app_notes_page_dto.dart';
import 'package:vestipro/features/settings/data/mappers/about_app_mapper.dart';
import 'package:vestipro/features/settings/data/mappers/about_app_notes_mapper.dart';
import 'package:vestipro/features/settings/data/models/about_app_seed_model.dart';
import 'package:vestipro/features/settings/data/repositories/about_app_repository_impl.dart';
import 'package:vestipro/features/settings/domain/usecases/get_about_app_use_case.dart';
import 'package:vestipro/features/settings/domain/usecases/search_about_app_notes_use_case.dart';
import 'package:vestipro/features/settings/domain/usecases/submit_about_app_diagnostics_use_case.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_bloc.dart';
import 'package:vestipro/features/settings/presentation/pages/about_app_page.dart';

void main() {
  group('AboutAppPage', () {
    testWidgets('renders loading state', (tester) async {
      final dataSource = _PendingAboutAppDataSource();

      await tester.pumpWidget(_buildPage(_buildUseCase(dataSource)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      dataSource.complete(_seed.toDto());
      await tester.pumpAndSettle();
    });

    testWidgets('renders success state', (tester) async {
      final dataSource = InMemoryAboutAppDataSource(seed: _seed);

      await tester.pumpWidget(_buildPage(_buildUseCase(dataSource)));
      await tester.pumpAndSettle();

      expect(find.text('VestiPro Dev'), findsWidgets);
      expect(find.text('Versao'), findsOneWidget);
      expect(find.text('1.0.0+1'), findsOneWidget);
      expect(find.text('Ambiente'), findsOneWidget);
      expect(find.text('development'), findsOneWidget);
      expect(find.text('Origem'), findsOneWidget);
      expect(find.text('Cache local'), findsOneWidget);
      expect(find.text('Estados completos'), findsOneWidget);
    });

    testWidgets('shows a debug-only crash test action that reports through '
        'FlutterError.onError (TASK-016)', (tester) async {
      final dataSource = InMemoryAboutAppDataSource(seed: _seed);

      await tester.pumpWidget(_buildPage(_buildUseCase(dataSource)));
      await tester.pumpAndSettle();

      final crashButton = find.byTooltip('Forcar crash de teste (Crashlytics)');
      expect(crashButton, findsOneWidget);

      await tester.tap(crashButton);
      expect(tester.takeException(), isA<StateError>());
    });

    testWidgets(
      'hides the Insights shortcut when showInsightsShortcut is false '
      '(TASK-018, feature_insights_enabled default)',
      (tester) async {
        final dataSource = InMemoryAboutAppDataSource(seed: _seed);

        await tester.pumpWidget(_buildPage(_buildUseCase(dataSource)));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Insights (feature flag)'), findsNothing);
      },
    );

    testWidgets(
      'shows the Insights shortcut end to end when showInsightsShortcut is '
      'true (TASK-018, feature_insights_enabled)',
      (tester) async {
        final dataSource = InMemoryAboutAppDataSource(seed: _seed);

        await tester.pumpWidget(
          _buildPage(_buildUseCase(dataSource), showInsightsShortcut: true),
        );
        await tester.pumpAndSettle();

        final insightsButton = find.byTooltip('Insights (feature flag)');
        expect(insightsButton, findsOneWidget);

        await tester.tap(insightsButton);
        await tester.pump();

        expect(find.textContaining('feature_insights_enabled'), findsOneWidget);
      },
    );

    testWidgets('renders error state', (tester) async {
      final dataSource = InMemoryAboutAppDataSource(
        seed: _seed,
        exception: const NetworkException('Offline.'),
      );

      await tester.pumpWidget(_buildPage(_buildUseCase(dataSource)));
      await tester.pumpAndSettle();

      expect(
        find.text('Nao foi possivel carregar as informacoes do app.'),
        findsOneWidget,
      );
      expect(find.text('Offline.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });
}

final _seed = AboutAppSeedModel.fromEnvironment(AppEnvironment.development);

Widget _buildPage(
  GetAboutAppUseCase useCase, {
  bool showInsightsShortcut = false,
}) {
  final repository = _buildRepository(InMemoryAboutAppDataSource(seed: _seed));

  return MaterialApp(
    home: AboutAppPage(
      createBloc: () => AboutAppBloc(
        getAboutApp: useCase,
        searchNotes: SearchAboutAppNotesUseCase(repository),
        submitDiagnostics: SubmitAboutAppDiagnosticsUseCase(repository),
      ),
      showInsightsShortcut: showInsightsShortcut,
    ),
  );
}

GetAboutAppUseCase _buildUseCase(AboutAppDataSource dataSource) {
  return GetAboutAppUseCase(_buildRepository(dataSource));
}

AboutAppRepositoryImpl _buildRepository(AboutAppDataSource dataSource) {
  final repository = AboutAppRepositoryImpl(
    dataSource: dataSource,
    mapper: const AboutAppMapper(),
    notesMapper: const AboutAppNotesMapper(),
  );

  return repository;
}

final class _PendingAboutAppDataSource implements AboutAppDataSource {
  final Completer<AboutAppDto> _completer = Completer<AboutAppDto>();

  @override
  Future<AboutAppDto> getAboutApp() {
    return _completer.future;
  }

  void complete(AboutAppDto dto) {
    _completer.complete(dto);
  }

  @override
  Future<AboutAppNotesPageDto> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  }) {
    return InMemoryAboutAppDataSource(
      seed: _seed,
    ).searchArchitectureNotes(query: query, page: page, pageSize: pageSize);
  }

  @override
  Future<void> submitDiagnostics() async {}
}
