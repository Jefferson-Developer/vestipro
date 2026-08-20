import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/errors/errors.dart';

part 'app_version.freezed.dart';

@freezed
abstract class AppVersion with _$AppVersion {
  const AppVersion._();

  const factory AppVersion({
    required int major,
    required int minor,
    required int patch,
    int? buildNumber,
  }) = _AppVersion;

  factory AppVersion.parse(String value) {
    final normalized = value.trim();
    final versionAndBuild = normalized.split('+');

    if (versionAndBuild.isEmpty || versionAndBuild.length > 2) {
      throw ValidationException(
        'Invalid app version.',
        code: 'invalid_version',
      );
    }

    final versionParts = versionAndBuild.first.split('.');
    if (versionParts.length != 3) {
      throw ValidationException(
        'Invalid app version.',
        code: 'invalid_version',
      );
    }

    final major = int.tryParse(versionParts[0]);
    final minor = int.tryParse(versionParts[1]);
    final patch = int.tryParse(versionParts[2]);
    final buildNumber = versionAndBuild.length == 2
        ? int.tryParse(versionAndBuild[1])
        : null;

    if (major == null ||
        minor == null ||
        patch == null ||
        major < 0 ||
        minor < 0 ||
        patch < 0 ||
        (versionAndBuild.length == 2 && buildNumber == null)) {
      throw ValidationException(
        'Invalid app version.',
        code: 'invalid_version',
      );
    }

    return AppVersion(
      major: major,
      minor: minor,
      patch: patch,
      buildNumber: buildNumber,
    );
  }

  String get displayValue {
    final baseVersion = '$major.$minor.$patch';
    final build = buildNumber;

    return build == null ? baseVersion : '$baseVersion+$build';
  }
}
