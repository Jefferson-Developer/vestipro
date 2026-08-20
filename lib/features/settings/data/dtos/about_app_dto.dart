import '../../../../core/errors/errors.dart';

final class AboutAppDto {
  const AboutAppDto({
    required this.name,
    required this.version,
    required this.environmentLabel,
    required this.updatedAtIso,
  });

  factory AboutAppDto.fromJson(Map<String, Object?> json) {
    final name = json['name'];
    final version = json['version'];
    final environmentLabel = json['environment_label'];
    final updatedAtIso = json['updated_at'];

    if (name is! String ||
        version is! String ||
        environmentLabel is! String ||
        updatedAtIso is! String) {
      throw const ValidationException(
        'Invalid about app payload.',
        code: 'invalid_about_app_payload',
      );
    }

    return AboutAppDto(
      name: name,
      version: version,
      environmentLabel: environmentLabel,
      updatedAtIso: updatedAtIso,
    );
  }

  final String name;
  final String version;
  final String environmentLabel;
  final String updatedAtIso;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'name': name,
      'version': version,
      'environment_label': environmentLabel,
      'updated_at': updatedAtIso,
    };
  }
}
