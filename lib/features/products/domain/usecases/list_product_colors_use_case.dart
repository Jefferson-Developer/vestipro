import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/product_color.dart';
import '../repositories/product_color_repository.dart';

@injectable
final class ListProductColorsUseCase {
  const ListProductColorsUseCase(this._repository);

  final ProductColorRepository _repository;

  Future<AppResult<List<ProductColor>>> call(String organizationId) {
    return _repository.listByOrganization(organizationId.trim());
  }
}
