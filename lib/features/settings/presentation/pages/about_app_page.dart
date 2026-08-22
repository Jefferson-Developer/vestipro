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
  const AboutAppPage({required this.createBloc, super.key});

  final AboutAppBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AboutAppBloc>(
      create: (_) => createBloc()..add(const AboutAppEvent.started()),
      child: const AboutAppView(),
    );
  }
}

class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AboutAppBloc, AboutAppState>(
      builder: (context, state) {
        return switch (state) {
          AboutAppInitial() || AboutAppLoading() => const Scaffold(
            appBar: _AboutAppBar(title: 'Sobre o app'),
            body: Center(child: CircularProgressIndicator()),
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
              appBar: _AboutAppBar(title: aboutApp.name),
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
            appBar: const _AboutAppBar(title: 'Sobre o app'),
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
  const _AboutAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [if (kDebugMode) const _CrashlyticsTestCrashButton()],
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
