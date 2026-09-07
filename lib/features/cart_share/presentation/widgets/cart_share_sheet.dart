import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/cart_share_models.dart';
import '../bloc/cart_share_cubit.dart';

class CartShareSheet extends StatefulWidget {
  const CartShareSheet({
    required this.organizationId,
    required this.sourceCartId,
    required this.sourceCartVersion,
    required this.items,
    required this.createCubit,
    super.key,
  });
  final String organizationId;
  final String sourceCartId;
  final int sourceCartVersion;
  final List<CartShareDraftItem> items;
  final CartShareCubit Function() createCubit;

  @override
  State<CartShareSheet> createState() => _CartShareSheetState();
}

class _CartShareSheetState extends State<CartShareSheet> {
  bool showPrices = false;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => widget.createCubit(),
    child: BlocBuilder<CartShareCubit, CartShareState>(
      builder: (context, state) {
        final issued = state.issued;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Compartilhar seleção', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                '${widget.items.length} variantes. A aprovação não envia o pedido.',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Solicitar exibição de preços'),
                subtitle: const Text(
                  'A política da organização sempre prevalece.',
                ),
                value: showPrices,
                onChanged: state.status == CartShareStatus.loading
                    ? null
                    : (value) => setState(() => showPrices = value),
              ),
              if (issued == null)
                FilledButton.icon(
                  onPressed: state.status == CartShareStatus.loading
                      ? null
                      : () => context.read<CartShareCubit>().create(
                          organizationId: widget.organizationId,
                          sourceCartId: widget.sourceCartId,
                          sourceCartVersion: widget.sourceCartVersion,
                          items: widget.items,
                          showPrices: showPrices,
                        ),
                  icon: const Icon(Icons.link),
                  label: const Text('Gerar link'),
                )
          else ...<Widget>[
            SelectableText('${Uri.base.origin}/cart-share/${issued.token}'),
            const SizedBox(height: AppSpacing.spacing8),
            const Text(
              'Este link é um snapshot. Se o carrinho mudar, gere um novo '
              'link para evitar que o cliente revise uma versão desatualizada.',
            ),
            const SizedBox(height: AppSpacing.spacing8),
                FilledButton.icon(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(
                      text: '${Uri.base.origin}/cart-share/${issued.token}',
                    ),
                  ),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar link'),
                ),
              ],
              if (state.failure != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.spacing8),
                  child: Text(
                    state.failure!.message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}
