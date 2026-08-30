import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../bloc/order_items_counter_cubit.dart';
import '../bloc/order_items_counter_state.dart';

/// "N produtos no pedido atual" indicator (TASK-097, EPIC-13) — B2B-worded
/// on purpose (never "carrinho"/"sacola" e-commerce terms). Renders nothing
/// for the empty state (no items on the draft yet): the catalog screen
/// should not show an empty counter bar taking up space before the seller
/// has added anything.
///
/// Reads `OrderItemsCounterCubit` from the surrounding `BlocProvider` —
/// callers own loading it (e.g. once per catalog screen visit).
class OrderItemsCounterIndicator extends StatelessWidget {
  const OrderItemsCounterIndicator({this.onTap, super.key});

  /// Called when the seller taps the indicator — the host navigates back to
  /// the draft summary.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderItemsCounterCubit, OrderItemsCounterState>(
      builder: (context, state) {
        if (!state.hasItems) return const SizedBox.shrink();
        return _OrderItemsCounterBar(itemCount: state.itemCount, onTap: onTap);
      },
    );
  }
}

class _OrderItemsCounterBar extends StatelessWidget {
  const _OrderItemsCounterBar({required this.itemCount, this.onTap});

  final int itemCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppRadius.radius8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        onTap: onTap,
        child: Semantics(
          button: true,
          label:
              '$itemCount ${itemCount == 1 ? 'produto' : 'produtos'} no '
              'pedido atual. Toque para ver o pedido.',
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
              vertical: AppSpacing.spacing12,
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.shopping_bag_outlined, color: colors.onPrimary),
                const SizedBox(width: AppSpacing.spacing8),
                Expanded(
                  child: Text(
                    '$itemCount ${itemCount == 1 ? 'produto' : 'produtos'} '
                    'no pedido atual',
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.onPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: colors.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
