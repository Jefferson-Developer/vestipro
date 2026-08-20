import '../../../../core/errors/errors.dart';
import '../dtos/about_app_dto.dart';
import '../dtos/about_app_note_dto.dart';
import '../dtos/about_app_notes_page_dto.dart';
import '../models/about_app_seed_model.dart';
import 'about_app_data_source.dart';

final class InMemoryAboutAppDataSource implements AboutAppDataSource {
  const InMemoryAboutAppDataSource({
    required this.seed,
    this.exception,
    this.delay = Duration.zero,
  });

  final AboutAppSeedModel seed;
  final AppException? exception;
  final Duration delay;

  @override
  Future<AboutAppDto> getAboutApp() async {
    await _simulateLatency();
    _throwIfNeeded();

    return seed.toDto();
  }

  @override
  Future<AboutAppNotesPageDto> searchArchitectureNotes({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    await _simulateLatency();
    _throwIfNeeded();

    final normalizedQuery = query.trim().toLowerCase();
    final filtered = _architectureNotes
        .where((note) {
          if (normalizedQuery.isEmpty) {
            return true;
          }

          return note.title.toLowerCase().contains(normalizedQuery) ||
              note.description.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);

    final safePage = page < 1 ? 1 : page;
    final safePageSize = pageSize < 1 ? 1 : pageSize;
    final start = (safePage - 1) * safePageSize;
    final end = (start + safePageSize).clamp(0, filtered.length);
    final items = start >= filtered.length
        ? const <AboutAppNoteDto>[]
        : filtered.sublist(start, end);

    return AboutAppNotesPageDto(
      items: items,
      page: safePage,
      hasMore: end < filtered.length,
      dataOrigin: 'local_cache',
    );
  }

  @override
  Future<void> submitDiagnostics() async {
    await _simulateLatency();
    _throwIfNeeded();
  }

  Future<void> _simulateLatency() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  void _throwIfNeeded() {
    final error = exception;
    if (error != null) {
      throw error;
    }
  }
}

const _architectureNotes = <AboutAppNoteDto>[
  AboutAppNoteDto(
    id: 'states',
    title: 'Estados completos',
    description: 'Cada estado emitido representa uma situacao consistente.',
  ),
  AboutAppNoteDto(
    id: 'events',
    title: 'Eventos por intencao',
    description: 'Eventos descrevem o que o usuario ou sistema tentou fazer.',
  ),
  AboutAppNoteDto(
    id: 'pagination',
    title: 'Paginacao preservada',
    description: 'Novas paginas sao anexadas sem perder itens ja carregados.',
  ),
  AboutAppNoteDto(
    id: 'origin',
    title: 'Origem do dado',
    description: 'Estados indicam cache local ou dado remoto sincronizado.',
  ),
  AboutAppNoteDto(
    id: 'transformers',
    title: 'Concorrencia previsivel',
    description: 'Buscas usam restartable; envios usam sequential.',
  ),
];
