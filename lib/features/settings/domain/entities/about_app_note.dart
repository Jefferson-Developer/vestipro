import 'package:freezed_annotation/freezed_annotation.dart';

part 'about_app_note.freezed.dart';

@freezed
abstract class AboutAppNote with _$AboutAppNote {
  const factory AboutAppNote({
    required String id,
    required String title,
    required String description,
  }) = _AboutAppNote;
}
