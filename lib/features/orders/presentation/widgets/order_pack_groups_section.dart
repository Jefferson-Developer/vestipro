import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/order_draft_bloc.dart';
import '../bloc/order_draft_event.dart';

/// "Kits e sortimentos" section of the order draft (TASK-208, EPIC-32):
/// every `OrderItem` produced by expanding a `CommercialPack`
/// (`ExpandCommercialPackToOrderItemsUseCase`), grouped back together by
/// `OrderItem.packGroupId` — never mixed into the plain per-product items
/// list (`_OrderItemsSection`), so the seller always sees "qual pacote/
/// versão originou cada item" as one visual unit instead of loose lines.
///
/// Each group shows the pack name/version snapshot and every resolved line
/// with its quantity/price, plus a single "Remover pacote" action
/// (`OrderDraftPackGroupRemoved`) that always removes the whole instance at
/// once, per this pack's own "a remoção de um pacote remove todos os itens
/// vinculados" business rule — there is deliberately no per-line removal
/// here.
class OrderPackGroupsSection extends StatelessWidget {
  const OrderPackGroupsSection({
    required this.items,
    required this.currency,
    super.key,
  });

  final List<OrderItem> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<OrderItem>>{};
    for (final item in items) {
      final packGroupId = item.packGroupId;
      if (packGroupId == null) continue;
      groups.putIfAbsent(packGroupId, () => <OrderItem>[]).add(item);
    }
    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Kits e sortimentos', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.spacing8),
        for (final entry in groups.entries) ...<Widget>[
          _PackGroupCard(
            packGroupId: entry.key,
            items: entry.value,
            currency: currency,
          ),
          const SizedBox(height: AppSpacing.spacing8),
        ],
      ],
    );
  }
}

class _PackGroupCard extends StatelessWidget {
  const _PackGroupCard({
    required this.packGroupId,
    required this.items,
    required this.currency,
  });

  final String packGroupId;
  final List<OrderItem> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final first = items.first;
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);

    return Container(
      key: ValueKey('order_pack_group_$packGroupId'),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      first.packName ?? 'Kit/pacote',
                      style: AppTypography.bodyLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    if (first.packVersion != null)
                      Text(
                        'Versão ${first.packVersion}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colors.outline,
                        ),
                      ),
                  ],
                ),
              ),
              AppIconButton(
                icon: Icons.delete_outline,
                semanticLabel:
                    'Remover ${first.packName ?? 'kit/pacote'} do '
                    'pedido',
                onPressed: () => context.read<OrderDraftBloc>().add(
                  OrderDraftPackGroupRemoved(packGroupId),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productId}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.formatWithCode(item.subtotal, currency),
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Subtotal do kit/pacote',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.formatWithCode(total, currency),
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
