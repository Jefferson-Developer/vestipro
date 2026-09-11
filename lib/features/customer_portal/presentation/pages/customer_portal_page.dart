import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/customer_portal_cubit.dart';

class CustomerPortalPage extends StatefulWidget {
  const CustomerPortalPage({
    required this.organizationId,
    required this.cubit,
    super.key,
  });
  final String organizationId;
  final CustomerPortalCubit cubit;
  @override
  State<CustomerPortalPage> createState() => _CustomerPortalPageState();
}

class _CustomerPortalPageState extends State<CustomerPortalPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.cubit.load(widget.organizationId));
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.cubit,
    child: BlocBuilder<CustomerPortalCubit, CustomerPortalState>(
      builder: (context, state) {
        if (state.status == CustomerPortalStatus.loading ||
            state.status == CustomerPortalStatus.initial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.status == CustomerPortalStatus.failure &&
            state.snapshot == null) {
          return Scaffold(body: Center(child: Text(state.failureMessage!)));
        }
        final portal = state.snapshot!;
        return Scaffold(
          appBar: AppBar(title: Text(portal.branding.name)),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 600
                  ? 3
                  : 2;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Catálogo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    childAspectRatio: 1.35,
                    children: portal.products
                        .map(
                          (product) => Card(
                            child: Semantics(
                              label: 'Produto ${product.name}',
                              child: Center(
                                child: Text(
                                  product.name,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Meus pedidos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (portal.orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Você ainda não possui pedidos.'),
                    ),
                  ...portal.orders.map(
                    (order) => Card(
                      child: ListTile(
                        title: Text('Pedido ${order.orderNumber}'),
                        subtitle: Text(
                          '${order.status} • R\$ ${order.total.toStringAsFixed(2)}'
                          '${order.shipmentStatus == null ? '' : '\nRastreio: ${order.shipmentStatus}'}'
                          '${order.hasOpenLogisticsIssue ? ' (ocorrência em aberto)' : ''}',
                        ),
                        isThreeLine: order.shipmentStatus != null,
                        trailing: FilledButton.tonal(
                          onPressed: () => context
                              .read<CustomerPortalCubit>()
                              .repeatOrder(widget.organizationId, order.id),
                          child: const Text('Repetir pedido'),
                        ),
                      ),
                    ),
                  ),
                  if (state.repeatedItems.isNotEmpty)
                    Text(
                      '${state.repeatedItems.length} itens revalidados com preço e estoque atuais.',
                    ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}
