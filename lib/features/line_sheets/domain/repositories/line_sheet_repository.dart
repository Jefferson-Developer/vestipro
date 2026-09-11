import '../../../../core/utils/utils.dart';
import '../entities/line_sheet.dart';

abstract interface class LineSheetRepository {
  Future<AppResult<LineSheetView>> getPublishedForCollection({
    required String organizationId,
    required String collectionId,
    required LineSheetAccessProfile profile,
    String? customerId,
  });
}
