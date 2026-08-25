import 'package:injectable/injectable.dart';

import '../entities/catalog_home_section_config.dart';
import '../repositories/catalog_home_config_repository.dart';

/// Resolves the catalog home's data-driven section composition (TASK-076).
/// Falls back to [defaultCatalogHomeSectionConfigs] whenever the repository
/// itself fails, so `CatalogHomeBloc` never has to special-case "no config
/// available" — the safe default always applies.
@injectable
final class GetCatalogHomeConfigUseCase {
  GetCatalogHomeConfigUseCase(this._repository);

  final CatalogHomeConfigRepository _repository;

  Future<List<CatalogHomeSectionConfig>> call(String organizationId) async {
    final result = await _repository.getSectionConfigs(organizationId.trim());
    return result.fold(
      onSuccess: (configs) =>
          configs.isEmpty ? defaultCatalogHomeSectionConfigs : configs,
      onFailure: (_) => defaultCatalogHomeSectionConfigs,
    );
  }
}
