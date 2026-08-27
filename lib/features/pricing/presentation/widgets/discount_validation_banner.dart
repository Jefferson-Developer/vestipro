import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/discount_validation_result.dart';

class DiscountValidationBanner extends StatelessWidget {
  const DiscountValidationBanner({required this.result, super.key});

  final DiscountValidationResult? result;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    if (result == null) return const SizedBox.shrink();

    if (result is DiscountAllowed) {
      return const _DiscountStatusSurface(
        title: 'Desconto dentro da política',
        description:
            'O desconto manual respeita o limite do perfil e pode seguir no pedido.',
        icon: Icons.verified_outlined,
        color: Colors.green,
      );
    }
    if (result is DiscountRequiresApproval) {
      return _DiscountStatusSurface(
        title: 'Desconto exige aprovação',
        description:
            'O perfil ultrapassou o gatilho automático e o pedido deve seguir para aprovação antes do envio.',
        icon: Icons.rule_folder_outlined,
        color: Colors.orange,
        footer: Text(
          'Contrato pronto para aprovação: ${result.approvalRequest.toJson()}',
          key: const ValueKey<String>('discount_approval_payload'),
        ),
      );
    }
    final blocked = result as DiscountBlocked;
    return _DiscountStatusSurface(
      title: 'Desconto bloqueado',
      description: blocked.reason,
      icon: Icons.block_outlined,
      color: Colors.red,
    );
  }
}

class _DiscountStatusSurface extends StatelessWidget {
  const _DiscountStatusSurface({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.footer,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Text(description),
            if (footer != null) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing12),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}
