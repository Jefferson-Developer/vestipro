import '../../core/environment/app_environment.dart';
import 'data/datasources/in_memory_about_app_datasource.dart';
import 'data/mappers/about_app_mapper.dart';
import 'data/mappers/about_app_notes_mapper.dart';
import 'data/models/about_app_seed_model.dart';
import 'data/repositories/about_app_repository_impl.dart';
import 'domain/repositories/about_app_repository.dart';
import 'domain/usecases/get_about_app_use_case.dart';
import 'domain/usecases/search_about_app_notes_use_case.dart';
import 'domain/usecases/submit_about_app_diagnostics_use_case.dart';

GetAboutAppUseCase createAboutAppUseCase(AppEnvironment environment) {
  final repository = createAboutAppRepository(environment);

  return GetAboutAppUseCase(repository);
}

AboutAppRepository createAboutAppRepository(AppEnvironment environment) {
  final seed = AboutAppSeedModel.fromEnvironment(environment);
  final dataSource = InMemoryAboutAppDataSource(seed: seed);
  const mapper = AboutAppMapper();
  const notesMapper = AboutAppNotesMapper();
  final repository = AboutAppRepositoryImpl(
    dataSource: dataSource,
    mapper: mapper,
    notesMapper: notesMapper,
  );

  return repository;
}

SearchAboutAppNotesUseCase createSearchAboutAppNotesUseCase(
  AppEnvironment environment,
) {
  return SearchAboutAppNotesUseCase(createAboutAppRepository(environment));
}

SubmitAboutAppDiagnosticsUseCase createSubmitAboutAppDiagnosticsUseCase(
  AppEnvironment environment,
) {
  return SubmitAboutAppDiagnosticsUseCase(
    createAboutAppRepository(environment),
  );
}
