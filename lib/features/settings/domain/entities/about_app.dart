import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/app_version.dart';

part 'about_app.freezed.dart';

@freezed
abstract class AboutApp with _$AboutApp {
  const factory AboutApp({
    required String name,
    required AppVersion version,
    required String environmentLabel,
    required DateTime updatedAt,
  }) = _AboutApp;
}
