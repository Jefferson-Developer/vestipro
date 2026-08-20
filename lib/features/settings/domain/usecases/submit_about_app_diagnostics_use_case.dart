import '../../../../core/utils/utils.dart';
import '../repositories/about_app_repository.dart';

final class SubmitAboutAppDiagnosticsUseCase {
  const SubmitAboutAppDiagnosticsUseCase(this._repository);

  final AboutAppRepository _repository;

  Future<AppResult<void>> call() {
    return _repository.submitDiagnostics();
  }
}
