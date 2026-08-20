import '../../../../core/utils/utils.dart';
import '../entities/about_app.dart';

abstract interface class AboutAppRepository {
  Future<AppResult<AboutApp>> getAboutApp();
}
