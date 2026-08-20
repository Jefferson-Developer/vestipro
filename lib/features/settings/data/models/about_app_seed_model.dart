import '../../../../core/environment/app_environment.dart';
import '../dtos/about_app_dto.dart';

final class AboutAppSeedModel {
  const AboutAppSeedModel({
    required this.name,
    required this.version,
    required this.environmentLabel,
    required this.updatedAtIso,
  });

  factory AboutAppSeedModel.fromEnvironment(AppEnvironment environment) {
    return AboutAppSeedModel(
      name: environment.appName,
      version: '1.0.0+1',
      environmentLabel: environment.value,
      updatedAtIso: '2026-08-20T00:00:00.000Z',
    );
  }

  final String name;
  final String version;
  final String environmentLabel;
  final String updatedAtIso;

  AboutAppDto toDto() {
    return AboutAppDto(
      name: name,
      version: version,
      environmentLabel: environmentLabel,
      updatedAtIso: updatedAtIso,
    );
  }
}
