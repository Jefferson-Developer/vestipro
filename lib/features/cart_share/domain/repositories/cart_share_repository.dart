import '../../../../core/utils/utils.dart';
import '../entities/cart_share_models.dart';

abstract interface class CartShareRepository {
  Future<AppResult<IssuedCartShare>> create({
    required String organizationId,
    required String sourceCartId,
    required int sourceCartVersion,
    required List<CartShareDraftItem> items,
    required bool showPrices,
  });

  Future<AppResult<CartSharePreview>> preview({required String token});

  Future<AppResult<void>> review({
    required String token,
    required CartShareDecision decision,
    String? comment,
    List<String> rejectedItemIds,
  });
}
