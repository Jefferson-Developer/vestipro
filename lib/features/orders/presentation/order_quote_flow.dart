import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/order.dart';
import '../domain/entities/quote.dart';
import '../domain/usecases/generate_order_quote_use_case.dart';

Future<AppResult<Quote>> generateQuoteFromDraft({
  required BuildContext context,
  required Order order,
  required GenerateOrderQuoteUseCase generateQuoteUseCase,
}) async {
  final result = await generateQuoteUseCase(order: order);
  if (!context.mounted) return result;

  switch (result) {
    case AppSuccess<Quote>(value: final quote):
      AppSnackbar.show(
        context,
        message:
            'Orcamento gerado ate ${_formatDate(quote.expiresAt)}. '
            'Precos serao revalidados na conversao em pedido.',
        variant: AppSnackbarVariant.success,
      );
    case AppFailure<Quote>(failure: final failure):
      AppSnackbar.show(
        context,
        message: failure.message,
        variant: AppSnackbarVariant.error,
      );
  }
  return result;
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/'
      '${local.year}';
}
