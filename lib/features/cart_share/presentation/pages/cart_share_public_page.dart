import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/cart_share_models.dart';
import '../bloc/cart_share_cubit.dart';

class CartSharePublicPage extends StatelessWidget {
  const CartSharePublicPage({
    required this.token,
    required this.createCubit,
    super.key,
  });
  final String token;
  final CartShareCubit Function() createCubit;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = createCubit();
      unawaited(cubit.load(token));
      return cubit;
    },
    child: _CartSharePublicView(token: token),
  );
}

class _CartSharePublicView extends StatefulWidget {
  const _CartSharePublicView({required this.token});
  final String token;
  @override
  State<_CartSharePublicView> createState() => _CartSharePublicViewState();
}

class _CartSharePublicViewState extends State<_CartSharePublicView> {
  final comment = TextEditingController();
  final rejected = <String>{};
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Revisar seleção')),
    body: BlocBuilder<CartShareCubit, CartShareState>(
      builder: (context, state) {
        if (state.status == CartShareStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == CartShareStatus.submitted) {
          return const AppEmptyState(
            icon: Icons.check_circle,
            title: 'Resposta enviada',
            description:
                'O vendedor recebeu sua revisão. O pedido ainda será finalizado por ele.',
          );
        }
        if (state.failure != null) {
          return AppErrorState(
            title: 'Não foi possível revisar',
            message: state.failure!.message,
            retryLabel: 'Tentar novamente',
            onRetry: () => context.read<CartShareCubit>().load(widget.token),
          );
        }
        final preview = state.preview;
        if (preview == null || preview.outcome != CartShareOutcome.valid) {
          return const AppEmptyState(
            icon: Icons.link_off,
            title: 'Link indisponível',
            description: 'Peça ao vendedor um novo link.',
          );
        }
        final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          children: <Widget>[
            if (preview.organizationName != null)
              Text(preview.organizationName!, style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.spacing12),
            ...preview.items.map(
              (item) => Card(
                child: CheckboxListTile(
                  value: rejected.contains(item.itemId),
                  onChanged: (value) => setState(
                    () => value == true
                        ? rejected.add(item.itemId)
                        : rejected.remove(item.itemId),
                  ),
                  title: Text(item.productName),
                  subtitle: Text(
                    'Variante ${item.variantId} • ${item.quantity} un.${preview.showPrices ? ' • ${currency.format(item.subtotal)}' : ''}',
                  ),
                  secondary: const Icon(Icons.inventory_2_outlined),
                ),
              ),
            ),
            if (preview.showPrices && preview.total != null)
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total: ${currency.format(preview.total)}',
                  style: AppTypography.titleMedium,
                ),
              ),
            TextField(
              controller: comment,
              maxLength: 1000,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentário ou alteração sugerida',
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.read<CartShareCubit>().review(
                token: widget.token,
                decision: CartShareDecision.approved,
                comment: comment.text,
                rejectedItemIds: rejected.toList(),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Aprovar seleção'),
            ),
            TextButton(
              onPressed: () => context.read<CartShareCubit>().review(
                token: widget.token,
                decision: CartShareDecision.changesRequested,
                comment: comment.text,
                rejectedItemIds: rejected.toList(),
              ),
              child: const Text('Sugerir alteração / recusar itens marcados'),
            ),
          ],
        );
      },
    ),
  );
}
