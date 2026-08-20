import '../../../../core/errors/errors.dart';
import '../../domain/entities/about_app_data_origin.dart';
import '../../domain/entities/about_app_note.dart';
import '../../domain/entities/about_app_notes_page.dart';
import '../dtos/about_app_note_dto.dart';
import '../dtos/about_app_notes_page_dto.dart';

final class AboutAppNotesMapper {
  const AboutAppNotesMapper();

  AboutAppNotesPage toEntity(AboutAppNotesPageDto dto) {
    return AboutAppNotesPage(
      items: dto.items.map(_toNote).toList(growable: false),
      page: dto.page,
      hasMore: dto.hasMore,
      dataOrigin: _toDataOrigin(dto.dataOrigin),
    );
  }

  AboutAppNote _toNote(AboutAppNoteDto dto) {
    return AboutAppNote(
      id: dto.id,
      title: dto.title,
      description: dto.description,
    );
  }

  AboutAppDataOrigin _toDataOrigin(String value) {
    return switch (value) {
      'local_cache' => AboutAppDataOrigin.localCache,
      'remote_synced' => AboutAppDataOrigin.remoteSynced,
      _ => throw ValidationException(
        'Invalid about app data origin.',
        code: 'invalid_about_app_data_origin',
        cause: value,
      ),
    };
  }
}
