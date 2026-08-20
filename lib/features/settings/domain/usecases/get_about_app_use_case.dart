import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/about_app.dart';
import '../repositories/about_app_repository.dart';

@injectable
final class GetAboutAppUseCase {
  const GetAboutAppUseCase(this._repository);

  final AboutAppRepository _repository;

  Future<AppResult<AboutApp>> call() {
    return _repository.getAboutApp();
  }
}
