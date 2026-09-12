import 'package:flutter/material.dart';

import '../../domain/sample_management.dart';

final class SampleInventoryPanel extends StatelessWidget {
  const SampleInventoryPanel({
    required this.title,
    required this.items,
    required this.currentUserId,
    required this.canManageAllSamples,
    super.key,
  });

  final String title;
  final List<SampleItem> items;
  final String currentUserId;
  final bool canManageAllSamples;

  @override
  Widget build(BuildContext context) {
    final visibleItems = canManageAllSamples
        ? items
        : items
              .where((item) => item.responsibleUserId == currentUserId)
              .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (visibleItems.isEmpty)
          const Text('Nenhuma peca de mostruario sob esta responsabilidade.')
        else
          ...visibleItems.map(
            (item) => Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text('Variante ${item.variantId}'),
                subtitle: Text(
                  '${_statusLabel(item.status)} - ${item.physicalCondition}',
                ),
                trailing: Text(_holderLabel(item.holderType)),
              ),
            ),
          ),
      ],
    );
  }

  String _statusLabel(SampleItemStatus status) {
    return switch (status) {
      SampleItemStatus.available => 'Disponivel',
      SampleItemStatus.checkedOut => 'Em campo',
      SampleItemStatus.consigned => 'Consignada',
      SampleItemStatus.damaged => 'Avariada',
      SampleItemStatus.lost => 'Perdida',
      SampleItemStatus.sold => 'Vendida',
      SampleItemStatus.returned => 'Devolvida',
    };
  }

  String _holderLabel(SampleHolderType holderType) {
    return switch (holderType) {
      SampleHolderType.warehouse => 'Deposito',
      SampleHolderType.salesRep => 'Representante',
      SampleHolderType.showroom => 'Showroom',
      SampleHolderType.customer => 'Cliente',
    };
  }
}
