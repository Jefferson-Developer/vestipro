import '../dtos/replenishment_suggestion_dto.dart';

abstract interface class ReplenishmentSuggestionDataSource {
  Future<List<ReplenishmentSuggestionDto>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    String? status,
    String? warehouseId,
  });
}
