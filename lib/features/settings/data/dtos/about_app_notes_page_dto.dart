import 'about_app_note_dto.dart';

final class AboutAppNotesPageDto {
  const AboutAppNotesPageDto({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.dataOrigin,
  });

  final List<AboutAppNoteDto> items;
  final int page;
  final bool hasMore;
  final String dataOrigin;
}
