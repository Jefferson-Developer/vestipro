import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/payment_term.dart';

class PaymentTermSelector extends StatelessWidget {
  const PaymentTermSelector({
    required this.paymentTerms,
    required this.selectedPaymentTermId,
    required this.onChanged,
    super.key,
    this.priceListId,
    this.label = 'Condição de pagamento',
    this.errorText,
  });

  final List<PaymentTerm> paymentTerms;
  final String? selectedPaymentTermId;
  final String? priceListId;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final availableTerms =
        paymentTerms
            .where((term) => term.isActive)
            .where((term) => term.isCompatibleWithPriceList(priceListId))
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));

    return AppDropdown<String>(
      options: availableTerms
          .map(
            (term) => AppDropdownOption<String>(
              value: term.id,
              label:
                  '${term.name} • prazo médio ${term.averageTermDays.toStringAsFixed(1)} dias',
            ),
          )
          .toList(growable: false),
      selectedValues: selectedPaymentTermId == null
          ? const <String>{}
          : <String>{selectedPaymentTermId!},
      onChanged: (selectedValues) =>
          onChanged(selectedValues.isEmpty ? null : selectedValues.first),
      closeSemanticLabel: 'Fechar seleção de condição de pagamento',
      label: label,
      hintText: availableTerms.isEmpty
          ? 'Nenhuma condição ativa compatível'
          : 'Selecione uma condição',
      errorText: errorText,
      semanticLabel: label,
      isDisabled: availableTerms.isEmpty,
    );
  }
}
