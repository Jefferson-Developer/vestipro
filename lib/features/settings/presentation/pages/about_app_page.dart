import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_about_app_use_case.dart';
import '../bloc/about_app_cubit.dart';
import '../bloc/about_app_state.dart';
import '../widgets/about_app_content.dart';
import '../widgets/about_app_error_view.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({required this.getAboutApp, super.key});

  final GetAboutAppUseCase getAboutApp;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AboutAppCubit>(
      create: (_) => AboutAppCubit(getAboutApp)..load(),
      child: const AboutAppView(),
    );
  }
}

class AboutAppView extends StatelessWidget {
  const AboutAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AboutAppCubit, AboutAppState>(
      builder: (context, state) {
        return switch (state) {
          AboutAppInitial() || AboutAppLoading() => const Scaffold(
            appBar: _AboutAppBar(title: 'Sobre o app'),
            body: Center(child: CircularProgressIndicator()),
          ),
          AboutAppLoaded(aboutApp: final aboutApp) => Scaffold(
            appBar: _AboutAppBar(title: aboutApp.name),
            body: AboutAppContent(aboutApp: aboutApp),
          ),
          AboutAppError(failure: final failure) => Scaffold(
            appBar: const _AboutAppBar(title: 'Sobre o app'),
            body: AboutAppErrorView(
              message: failure.message,
              onRetry: context.read<AboutAppCubit>().load,
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
    return AppBar(title: Text(title));
  }
}
