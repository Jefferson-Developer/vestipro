import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/cart_share_models.dart';
import '../repositories/cart_share_repository.dart';

@injectable
final class CreateCartShareUseCase {
  const CreateCartShareUseCase(this._repository);
  final CartShareRepository _repository;

  Future<AppResult<IssuedCartShare>> call({
    required String organizationId,
    required String sourceCartId,
    required int sourceCartVersion,
    required List<CartShareDraftItem> items,
    required bool showPrices,
  }) {
    if (organizationId.trim().isEmpty ||
        sourceCartId.trim().isEmpty ||
        items.isEmpty) {
      return Future.value(
        const AppFailure(
          ValidationFailure(
            'O carrinho precisa ter itens para ser compartilhado.',
          ),
        ),
      );
    }
    return _repository.create(
      organizationId: organizationId.trim(),
      sourceCartId: sourceCartId.trim(),
      sourceCartVersion: sourceCartVersion,
      items: items,
      showPrices: showPrices,
    );
  }
}

@injectable
final class PreviewCartShareUseCase {
  const PreviewCartShareUseCase(this._repository);
  final CartShareRepository _repository;
  Future<AppResult<CartSharePreview>> call(String token) =>
      _repository.preview(token: token.trim());
}

@injectable
final class ReviewCartShareUseCase {
  const ReviewCartShareUseCase(this._repository);
  final CartShareRepository _repository;
  Future<AppResult<void>> call({
    required String token,
    required CartShareDecision decision,
    String? comment,
    List<String> rejectedItemIds = const <String>[],
  }) {
    if (decision == CartShareDecision.changesRequested &&
        (comment == null || comment.trim().isEmpty)) {
      return Future.value(
        const AppFailure(ValidationFailure('Descreva a alteração sugerida.')),
      );
    }
    return _repository.review(
      token: token.trim(),
      decision: decision,
      comment: comment?.trim(),
      rejectedItemIds: rejectedItemIds,
    );
  }
}
