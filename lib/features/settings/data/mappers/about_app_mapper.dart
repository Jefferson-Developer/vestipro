import 'package:injectable/injectable.dart';

import '../../domain/entities/about_app.dart';
import '../../domain/value_objects/app_version.dart';
import '../dtos/about_app_dto.dart';

@lazySingleton
final class AboutAppMapper {
  const AboutAppMapper();

  AboutApp toEntity(AboutAppDto dto) {
    return AboutApp(
      name: dto.name,
      version: AppVersion.parse(dto.version),
      environmentLabel: dto.environmentLabel,
      updatedAt: DateTime.parse(dto.updatedAtIso),
    );
  }
}
