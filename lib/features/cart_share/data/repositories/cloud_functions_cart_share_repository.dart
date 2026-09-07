import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/cart_share_models.dart';
import '../../domain/repositories/cart_share_repository.dart';

@LazySingleton(as: CartShareRepository)
final class CloudFunctionsCartShareRepository implements CartShareRepository {
  const CloudFunctionsCartShareRepository(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<AppResult<IssuedCartShare>> create({
    required String organizationId,
    required String sourceCartId,
    required int sourceCartVersion,
    required List<CartShareDraftItem> items,
    required bool showPrices,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'createCartShareLink',
      requireAuth: true,
      data: <String, dynamic>{
        'organizationId': organizationId,
        'sourceCartId': sourceCartId,
        'sourceCartVersion': sourceCartVersion,
        'showPrices': showPrices,
        'items': items
            .map(
              (item) => <String, dynamic>{
                'itemId': item.itemId,
                'productId': item.productId,
                'productName': item.productName,
                'variantId': item.variantId,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
              },
            )
            .toList(growable: false),
      },
    );
    return IssuedCartShare(
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      showPrices: json['showPrices'] as bool,
    );
  });

  @override
  Future<AppResult<CartSharePreview>> preview({required String token}) =>
      _guard(() async {
        final json = await _functions.call<Map<String, dynamic>>(
          'getCartShareLink',
          data: <String, dynamic>{'token': token},
          requireAuth: false,
        );
        final outcome = switch (json['outcome']) {
          'valid' => CartShareOutcome.valid,
          'expired' => CartShareOutcome.expired,
          'revoked' => CartShareOutcome.revoked,
          _ => CartShareOutcome.notFound,
        };
        final rawItems = (json['items'] as List<dynamic>? ?? const <dynamic>[]);
        return CartSharePreview(
          outcome: outcome,
          organizationName: json['organizationName'] as String?,
          showPrices: json['showPrices'] as bool? ?? false,
          items: rawItems
              .map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                return CartShareItem(
                  itemId: item['itemId'] as String,
                  productName: item['productName'] as String,
                  variantId: item['variantId'] as String,
                  quantity: item['quantity'] as int,
                  unitPrice: (item['unitPrice'] as num?)?.toDouble(),
                  subtotal: (item['subtotal'] as num?)?.toDouble(),
                );
              })
              .toList(growable: false),
          total: (json['total'] as num?)?.toDouble(),
          expiresAt: json['expiresAt'] == null
              ? null
              : DateTime.parse(json['expiresAt'] as String),
        );
      });

  @override
  Future<AppResult<void>> review({
    required String token,
    required CartShareDecision decision,
    String? comment,
    List<String> rejectedItemIds = const <String>[],
  }) => _guard(() async {
    await _functions.call<Map<String, dynamic>>(
      'reviewCartShare',
      requireAuth: false,
      data: <String, dynamic>{
        'token': token,
        'decision': decision == CartShareDecision.approved
            ? 'approved'
            : 'changesRequested',
        'comment': comment,
        'rejectedItemIds': rejectedItemIds,
      },
    );
  });

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Falha inesperada no compartilhamento do carrinho.',
          cause: error,
        ),
      );
    }
  }
}
