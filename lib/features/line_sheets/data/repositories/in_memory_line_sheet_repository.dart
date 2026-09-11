import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/line_sheet.dart';
import '../../domain/repositories/line_sheet_repository.dart';

final class InMemoryLineSheetRepository implements LineSheetRepository {
  InMemoryLineSheetRepository([
    Iterable<LineSheet> seed = const <LineSheet>[],
  ]) {
    for (final lineSheet in seed) {
      upsert(lineSheet);
    }
  }

  final Map<String, LineSheet> _lineSheets = <String, LineSheet>{};

  void upsert(LineSheet lineSheet) => _lineSheets[lineSheet.id] = lineSheet;

  @override
  Future<AppResult<LineSheetView>> getPublishedForCollection({
    required String organizationId,
    required String collectionId,
    required LineSheetAccessProfile profile,
    String? customerId,
  }) async {
    final candidates =
        _lineSheets.values
            .where(
              (lineSheet) =>
                  lineSheet.organizationId == organizationId &&
                  lineSheet.collectionId == collectionId &&
                  lineSheet.isPublished,
            )
            .toList(growable: false)
          ..sort((a, b) => b.version.compareTo(a.version));
    if (candidates.isEmpty) {
      return const AppFailure<LineSheetView>(
        NotFoundFailure(
          'Line sheet publicado nao encontrado para a colecao.',
          code: 'line_sheet_not_found',
        ),
      );
    }
    final lineSheet = candidates.first;
    if (!lineSheet.accessPolicy.allows(
      profile: profile,
      customerId: customerId,
    )) {
      return const AppFailure<LineSheetView>(
        PermissionFailure(
          'Perfil sem acesso a este line sheet.',
          code: 'line_sheet_access_denied',
        ),
      );
    }
    return AppSuccess<LineSheetView>(
      LineSheetView(
        lineSheet: lineSheet,
        profile: profile,
        customerId: customerId,
      ),
    );
  }
}
