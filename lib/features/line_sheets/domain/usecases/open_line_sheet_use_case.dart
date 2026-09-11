import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/line_sheet.dart';
import '../entities/line_sheet_order_form.dart';
import '../repositories/line_sheet_repository.dart';

final class OpenLineSheetUseCase {
  const OpenLineSheetUseCase({
    required this.repository,
    required this.analyticsService,
  });

  final LineSheetRepository repository;
  final AnalyticsService analyticsService;

  Future<AppResult<LineSheetView>> call({
    required String organizationId,
    required String collectionId,
    required LineSheetAccessProfile profile,
    String? customerId,
  }) async {
    final result = await repository.getPublishedForCollection(
      organizationId: organizationId,
      collectionId: collectionId,
      profile: profile,
      customerId: customerId,
    );
    return result.fold(
      onSuccess: (view) async {
        await analyticsService.logEvent(
          AnalyticsEvents.lineSheetOpened,
          parameters: <String, Object?>{
            'line_sheet_id': view.lineSheet.id,
            'collection_id': view.lineSheet.collectionId,
            'line_sheet_version': view.lineSheet.version,
            'profile': profile.name,
          },
        );
        return AppSuccess<LineSheetView>(view);
      },
      onFailure: (failure) => AppFailure<LineSheetView>(failure),
    );
  }
}

final class StartLineSheetOrderFormUseCase {
  const StartLineSheetOrderFormUseCase();

  AppResult<LineSheetOrderFormDraft> call(LineSheetView view) {
    if (!view.lineSheet.isPublished) {
      return const AppFailure<LineSheetOrderFormDraft>(
        ValidationFailure(
          'O line sheet precisa estar publicado para gerar pedido.',
          code: 'line_sheet_not_published',
        ),
      );
    }
    return AppSuccess<LineSheetOrderFormDraft>(
      LineSheetOrderFormDraft(
        lineSheetId: view.lineSheet.id,
        lineSheetVersion: view.lineSheet.version,
        collectionId: view.lineSheet.collectionId,
        cells: const <String, LineSheetOrderFormCell>{},
      ),
    );
  }
}
