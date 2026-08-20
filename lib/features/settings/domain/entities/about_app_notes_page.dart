import 'package:freezed_annotation/freezed_annotation.dart';

import 'about_app_data_origin.dart';
import 'about_app_note.dart';

part 'about_app_notes_page.freezed.dart';

@freezed
abstract class AboutAppNotesPage with _$AboutAppNotesPage {
  const factory AboutAppNotesPage({
    required List<AboutAppNote> items,
    required int page,
    required bool hasMore,
    required AboutAppDataOrigin dataOrigin,
  }) = _AboutAppNotesPage;
}
