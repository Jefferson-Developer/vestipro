import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App version and platform metadata attached by [CloudFunctionsService] to
/// every callable request, under the reserved `_meta` key (kept out of the
/// caller-defined `data` fields to avoid colliding with each function's own
/// request shape — see `functions/src/shared/callable-meta.ts`, its
/// server-side counterpart).
final class AppClientMetadata {
  const AppClientMetadata({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
  });

  final String appVersion;
  final String buildNumber;
  final String platform;

  Map<String, String> toJson() => {
    'appVersion': appVersion,
    'buildNumber': buildNumber,
    'platform': platform,
  };
}

/// Resolves [AppClientMetadata], behind an interface so it can be mocked in
/// unit tests without depending on the `package_info_plus` platform channel
/// (same reasoning as `ImageCompressor` abstracting `flutter_image_compress`,
/// TASK-014).
abstract interface class AppClientMetadataProvider {
  Future<AppClientMetadata> resolve();
}

@LazySingleton(as: AppClientMetadataProvider)
final class PackageInfoClientMetadataProvider
    implements AppClientMetadataProvider {
  AppClientMetadata? _cached;

  @override
  Future<AppClientMetadata> resolve() async {
    final cached = _cached;
    if (cached != null) return cached;

    final packageInfo = await PackageInfo.fromPlatform();
    final resolved = AppClientMetadata(
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      platform: _platformName,
    );
    _cached = resolved;
    return resolved;
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return Platform.operatingSystem;
  }
}
