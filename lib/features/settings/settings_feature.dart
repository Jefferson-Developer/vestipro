import '../../core/environment/app_environment.dart';
import 'data/datasources/in_memory_about_app_datasource.dart';
import 'data/mappers/about_app_mapper.dart';
import 'data/models/about_app_seed_model.dart';
import 'data/repositories/about_app_repository_impl.dart';
import 'domain/usecases/get_about_app_use_case.dart';

GetAboutAppUseCase createAboutAppUseCase(AppEnvironment environment) {
  final seed = AboutAppSeedModel.fromEnvironment(environment);
  final dataSource = InMemoryAboutAppDataSource(seed: seed);
  const mapper = AboutAppMapper();
  final repository = AboutAppRepositoryImpl(
    dataSource: dataSource,
    mapper: mapper,
  );

  return GetAboutAppUseCase(repository);
}
