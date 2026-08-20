import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/injection.dart';
import 'package:vestipro/core/environment/app_environment.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/settings/data/datasources/about_app_data_source.dart';
import 'package:vestipro/features/settings/data/datasources/in_memory_about_app_datasource.dart';
import 'package:vestipro/features/settings/domain/entities/about_app.dart';
import 'package:vestipro/features/settings/domain/repositories/about_app_repository.dart';
import 'package:vestipro/features/settings/domain/usecases/get_about_app_use_case.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_bloc.dart';

void main() {
  setUp(resetDependencies);
  tearDown(resetDependencies);

  test('configureDependencies resolves the settings dependency graph', () {
    configureDependencies(AppEnvironment.development);

    expect(getIt<AboutAppDataSource>(), isA<InMemoryAboutAppDataSource>());
    expect(getIt<AboutAppRepository>(), isA<AboutAppRepository>());
    expect(getIt<GetAboutAppUseCase>(), isA<GetAboutAppUseCase>());
  });

  test('registered lifetimes match the DI convention', () {
    configureDependencies(AppEnvironment.development);

    final firstDataSource = getIt<AboutAppDataSource>();
    final secondDataSource = getIt<AboutAppDataSource>();
    expect(identical(firstDataSource, secondDataSource), isTrue);

    final firstBloc = getIt<AboutAppBloc>();
    final secondBloc = getIt<AboutAppBloc>();
    addTearDown(firstBloc.close);
    addTearDown(secondBloc.close);

    expect(identical(firstBloc, secondBloc), isFalse);
  });

  test('resolved AboutAppBloc receives the real use case graph', () async {
    configureDependencies(AppEnvironment.staging);

    final bloc = getIt<AboutAppBloc>();
    addTearDown(bloc.close);

    expect(bloc.getAboutApp, isA<GetAboutAppUseCase>());

    final result = await bloc.getAboutApp();

    expect(result, isA<AppSuccess<AboutApp>>());
    expect(
      (result as AppSuccess<AboutApp>).value.environmentLabel,
      AppEnvironment.staging.value,
    );
  });
}
