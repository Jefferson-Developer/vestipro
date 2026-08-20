import '../dtos/about_app_dto.dart';

abstract interface class AboutAppDataSource {
  Future<AboutAppDto> getAboutApp();
}
