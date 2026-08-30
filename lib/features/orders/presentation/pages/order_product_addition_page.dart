import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../catalog/catalog.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/order_item.dart';
import '../bloc/order_product_addition_cubit.dart';
import '../bloc/order_product_addition_state.dart';

/// Wraps the catalog's `ProductDetailPage` (TASK-077/078 — variant/size
/// selection, quantity, price feedback, availability, all reused as-is) with
/// the TASK-097 glue that turns a confirmed "adicionar ao pedido" tap into
/// persisted `OrderItem`s on the `Order` draft [draftId].
///
/// Pops back to `OrderProductCatalogRoute` with `true` only once the
/// addition actually persisted successfully — that `true` is what tells the
/// catalog screen to reload its "produtos no pedido atual" indicator. A
/// failed persistence never navigates away silently: it is surfaced with a
/// snackbar and the seller stays right here to retry the same tap.
class OrderProductAdditionPage extends StatelessWidget {
  const OrderProductAdditionPage({
    required this.organizationId,
    required this.companyId,
    required this.draftId,
    required this.productId,
    required this.createProductDetailBloc,
    required this.createAdditionCubit,
    this.origin = 'grid',
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String draftId;
  final String productId;
  final ProductDetailBloc Function() createProductDetailBloc;
  final OrderProductAdditionCubit Function() createAdditionCubit;
  final String origin;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderProductAdditionCubit>(
      create: (_) => createAdditionCubit(),
      child: BlocListener<OrderProductAdditionCubit, OrderProductAdditionState>(
        listener: (context, state) {
          switch (state.status) {
            case OrderProductAdditionStatus.success:
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produto adicionado ao pedido.')),
              );
              context.pop(true);
            case OrderProductAdditionStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.failure?.message ??
                        'Não foi possível adicionar o produto ao pedido.',
                  ),
                ),
              );
            case OrderProductAdditionStatus.idle:
            case OrderProductAdditionStatus.submitting:
              break;
          }
        },
        child: ProductDetailPage(
          organizationId: organizationId,
          productId: productId,
          origin: origin,
          createBloc: createProductDetailBloc,
          onAddToOrder: (product, lines) =>
              _addToOrder(context, product, lines),
        ),
      ),
    );
  }

  void _addToOrder(
    BuildContext context,
    Product product,
    List<ProductDetailOrderLine> lines,
  ) {
    const uuid = Uuid();
    final items = <OrderItem>[
      for (final line in lines)
        OrderItem(
          id: uuid.v4(),
          variantId: line.variant.id,
          productId: line.variant.productId,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          subtotal: line.quantity * line.unitPrice,
        ),
    ];
    if (items.isEmpty) return;
    unawaited(
      context.read<OrderProductAdditionCubit>().add(
        organizationId: organizationId,
        companyId: companyId,
        draftId: draftId,
        items: items,
      ),
    );
  }
}
