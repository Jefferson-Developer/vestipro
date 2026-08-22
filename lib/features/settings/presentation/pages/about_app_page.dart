import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/services.dart';
import '../bloc/about_app_bloc.dart';
import '../bloc/about_app_event.dart';
import '../bloc/about_app_state.dart';
import '../widgets/about_app_content.dart';
import '../widgets/about_app_error_view.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({
    required this.createBloc,
    this.showInsightsShortcut = false,
    super.key,
  });

  final AboutAppBloc Function() createBloc;

  /// Feature-flagged shortcut (TASK-018, `feature_insights_enabled`)
  /// created to validate the Remote Config pipeline end to end in this
  /// reference module. Resolved once at the composition boundary
  /// (`lib/app/injection.dart`, through `FeatureFlagService`) and passed in
  /// here — this widget never reads the flag itself, it only renders what
  /// it is told, same as every other constructor parameter.
  final bool showInsightsShortcut;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AboutAppBloc>(
      create: (_) => createBloc()..add(const AboutAppEvent.started()),
      child: AboutAppView(showInsightsShortcut: showInsightsShortcut),
    );
  }
}

class AboutAppView extends StatelessWidget {
  const AboutAppView({this.showInsightsShortcut = false, super.key});

  final bool showInsightsShortcut;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AboutAppBloc, AboutAppState>(
      builder: (context, state) {
        return switch (state) {
          AboutAppInitial() || AboutAppLoading() => Scaffold(
            appBar: _AboutAppBar(
              title: 'Sobre o app',
              showInsightsShortcut: showInsightsShortcut,
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          AboutAppReady(
            aboutApp: final aboutApp,
            notes: final notes,
            query: final query,
            hasMore: final hasMore,
            dataOrigin: final dataOrigin,
            isLoadingNextPage: final isLoadingNextPage,
            submissionStatus: final submissionStatus,
            submissionFailure: final submissionFailure,
          ) =>
            Scaffold(
              appBar: _AboutAppBar(
                title: aboutApp.name,
                showInsightsShortcut: showInsightsShortcut,
              ),
              body: AboutAppContent(
                aboutApp: aboutApp,
                notes: notes,
                query: query,
                hasMore: hasMore,
                dataOrigin: dataOrigin,
                isLoadingNextPage: isLoadingNextPage,
                submissionStatus: submissionStatus,
                submissionFailure: submissionFailure,
                onSearchChanged: (query) => context.read<AboutAppBloc>().add(
                  AboutAppEvent.searchQueryChanged(query),
                ),
                onLoadMore: () => context.read<AboutAppBloc>().add(
                  const AboutAppEvent.nextPageRequested(),
                ),
                onSubmitDiagnostics: () => context.read<AboutAppBloc>().add(
                  const AboutAppEvent.diagnosticsSubmitted(),
                ),
              ),
            ),
          AboutAppFailure(failure: final failure) => Scaffold(
            appBar: _AboutAppBar(
              title: 'Sobre o app',
              showInsightsShortcut: showInsightsShortcut,
            ),
            body: AboutAppErrorView(
              message: failure.message,
              onRetry: () => context.read<AboutAppBloc>().add(
                const AboutAppEvent.started(),
              ),
            ),
          ),
        };
      },
    );
  }
}

class _AboutAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AboutAppBar({required this.title, this.showInsightsShortcut = false});

  final String title;
  final bool showInsightsShortcut;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (showInsightsShortcut) const _InsightsShortcutButton(),
        if (kDebugMode) const _CrashlyticsTestCrashButton(),
      ],
    );
  }
}

/// Feature-flagged placeholder (TASK-018, `feature_insights_enabled`)
/// validating the Remote Config pipeline end to end: only rendered when
/// `FeatureFlagService.isEnabled(FeatureFlagRegistry.featureInsightsEnabled)`
/// is `true` (see `AboutAppPage.showInsightsShortcut`). No real Insights
/// module exists yet (EPIC-17); tapping it only confirms the flag reached
/// this widget.
class _InsightsShortcutButton extends StatelessWidget {
  const _InsightsShortcutButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.insights_outlined),
      tooltip: 'Insights (feature flag)',
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Insights Comerciais chega no EPIC-17 — atalho controlado '
              'por feature_insights_enabled (Remote Config).',
            ),
          ),
        );
      },
    );
  }
}

/// Debug/dev-only affordance (TASK-016) to confirm that an uncaught error
/// really reaches the Firebase Crashlytics console: never shown outside
/// [kDebugMode].
class _CrashlyticsTestCrashButton extends StatelessWidget {
  const _CrashlyticsTestCrashButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.bug_report_outlined),
      tooltip: 'Forcar crash de teste (Crashlytics)',
      onPressed: triggerCrashlyticsTestCrash,
    );
  }
}
