import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/buyer_collaboration_comment.dart';
import '../../domain/value_objects/buyer_collaboration_comment_kind.dart';
import '../../domain/value_objects/buyer_collaboration_status.dart';
import '../bloc/buyer_collaboration_cubit.dart';
import '../bloc/buyer_collaboration_state.dart';

/// Which side of the negotiation is looking at [BuyerCollaborationPanel] —
/// drives which actions are offered, never which data is fetched (that is
/// entirely `firestore.rules`' job: a buyer simply never receives a session
/// belonging to another `customerId` in the first place).
enum BuyerCollaborationViewerRole { seller, buyer }

/// Renders one `BuyerCollaborationSession` (TASK-211): item snapshot,
/// ordered comment history and the role-appropriate actions for its current
/// status. Used both as a bottom sheet from the seller's order draft screen
/// and as the buyer's own customer-portal screen — same widget, same Cubit,
/// only [role] changes what a viewer can do.
class BuyerCollaborationPanel extends StatefulWidget {
  const BuyerCollaborationPanel({
    required this.organizationId,
    required this.sessionId,
    required this.role,
    required this.createCubit,
    this.onConvertRequested,
    super.key,
  });

  final String organizationId;
  final String sessionId;
  final BuyerCollaborationViewerRole role;
  final BuyerCollaborationCubit Function() createCubit;

  /// Seller-only: asked when the seller taps "Converter em pedido" — the
  /// host screen owns navigating to/submitting the actual `Order` (TASK-096/
  /// TASK-101, itself running the real price/stock revalidation) and
  /// returns the resulting `orderId` once submitted, or `null` if the seller
  /// cancelled. This panel then only asks
  /// `convertBuyerCollaborationSession` to link it and enforce the
  /// additional price-drift check (`tasks.md`'s "revalidada [...] no
  /// momento da conversão").
  final Future<String?> Function()? onConvertRequested;

  @override
  State<BuyerCollaborationPanel> createState() =>
      _BuyerCollaborationPanelState();
}

class _BuyerCollaborationPanelState extends State<BuyerCollaborationPanel> {
  final TextEditingController _commentController = TextEditingController();
  late final BuyerCollaborationCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.createCubit()
      ..watch(
        organizationId: widget.organizationId,
        sessionId: widget.sessionId,
      );
  }

  @override
  void dispose() {
    _commentController.dispose();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BuyerCollaborationCubit>.value(
      value: _cubit,
      child: BlocConsumer<BuyerCollaborationCubit, BuyerCollaborationState>(
        listenWhen: (previous, current) =>
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == BuyerCollaborationActionStatus.failure &&
              state.actionFailure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.actionFailure!.message)),
            );
          }
          final conversion = state.lastConversion;
          if (conversion != null && !conversion.converted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'O preço de um ou mais itens mudou desde a aprovação. '
                  'Revise antes de converter.',
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.session == null &&
              state.loadStatus == BuyerCollaborationLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final session = state.session;
          if (session == null) {
            return const Center(
              child: Text('Sessão de colaboração não encontrada.'),
            );
          }
          final status = session.effectiveStatus(DateTime.now());
          final busy =
              state.actionStatus == BuyerCollaborationActionStatus.submitting;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            children: <Widget>[
              Text(
                'Colaboração com comprador',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.spacing8),
              _StatusChip(status: status),
              const SizedBox(height: AppSpacing.spacing16),
              ...session.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName),
                  subtitle: Text('${item.quantity}x — ${item.variantId}'),
                  trailing: session.showPrices
                      ? Text(item.subtotal.toStringAsFixed(2))
                      : null,
                ),
              ),
              if (session.showPrices)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacing8,
                  ),
                  child: Text(
                    'Total: ${session.currentTotal.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium,
                  ),
                ),
              const Divider(),
              Text('Histórico', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.spacing8),
              if (state.comments.isEmpty)
                const Text('Nenhum comentário ainda.')
              else
                ...state.comments.map(
                  (comment) => _CommentTile(comment: comment),
                ),
              const SizedBox(height: AppSpacing.spacing16),
              TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 3,
                enabled: !busy,
                decoration: const InputDecoration(
                  labelText: 'Escrever um comentário',
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Wrap(
                spacing: AppSpacing.spacing8,
                runSpacing: AppSpacing.spacing8,
                children: _buildActions(context, status, busy),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    BuyerCollaborationStatus status,
    bool busy,
  ) {
    final cubit = context.read<BuyerCollaborationCubit>();
    final actions = <Widget>[
      OutlinedButton.icon(
        onPressed: busy ? null : () => _submitComment(cubit),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Comentar'),
      ),
    ];

    if (widget.role == BuyerCollaborationViewerRole.seller) {
      if (status == BuyerCollaborationStatus.sellerDraft) {
        actions.add(
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => cubit.share(
                    organizationId: widget.organizationId,
                    sessionId: widget.sessionId,
                  ),
            icon: const Icon(Icons.send),
            label: const Text('Compartilhar com o comprador'),
          ),
        );
      }
      if (status == BuyerCollaborationStatus.changesRequested) {
        actions.add(
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => cubit.share(
                    organizationId: widget.organizationId,
                    sessionId: widget.sessionId,
                  ),
            icon: const Icon(Icons.send),
            label: const Text('Reenviar para revisão'),
          ),
        );
      }
      if (status == BuyerCollaborationStatus.buyerApproved) {
        actions.add(
          FilledButton.icon(
            onPressed: busy ? null : () => _handleConvert(context, cubit),
            icon: const Icon(Icons.shopping_cart_checkout),
            label: const Text('Converter em pedido'),
          ),
        );
      }
      if (status == BuyerCollaborationStatus.expired) {
        actions.add(
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => cubit.reopen(
                    organizationId: widget.organizationId,
                    sessionId: widget.sessionId,
                  ),
            icon: const Icon(Icons.restore),
            label: const Text('Reabrir sessão'),
          ),
        );
      }
    } else {
      if (status == BuyerCollaborationStatus.buyerReview) {
        actions.add(
          FilledButton.icon(
            onPressed: busy
                ? null
                : () => cubit.approve(
                    organizationId: widget.organizationId,
                    sessionId: widget.sessionId,
                  ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Aprovar seleção'),
          ),
        );
        actions.add(
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () => _handleRequestChanges(context, cubit),
            icon: const Icon(Icons.edit_note),
            label: const Text('Solicitar alterações'),
          ),
        );
      }
    }
    return actions;
  }

  void _submitComment(BuyerCollaborationCubit cubit) {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    unawaited(
      cubit.addComment(
        organizationId: widget.organizationId,
        sessionId: widget.sessionId,
        body: body,
      ),
    );
    _commentController.clear();
  }

  Future<void> _handleConvert(
    BuildContext context,
    BuyerCollaborationCubit cubit,
  ) async {
    final onConvertRequested = widget.onConvertRequested;
    if (onConvertRequested == null) return;
    final orderId = await onConvertRequested();
    if (orderId == null || orderId.trim().isEmpty) return;
    await cubit.convert(
      organizationId: widget.organizationId,
      sessionId: widget.sessionId,
      orderId: orderId.trim(),
    );
  }

  Future<void> _handleRequestChanges(
    BuildContext context,
    BuyerCollaborationCubit cubit,
  ) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Solicitar alterações'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'O que você gostaria de ajustar?',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (comment == null || comment.isEmpty) return;
    await cubit.requestChanges(
      organizationId: widget.organizationId,
      sessionId: widget.sessionId,
      comment: comment,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final BuyerCollaborationStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      BuyerCollaborationStatus.sellerDraft => 'Rascunho do vendedor',
      BuyerCollaborationStatus.buyerReview => 'Aguardando o comprador',
      BuyerCollaborationStatus.changesRequested => 'Alterações solicitadas',
      BuyerCollaborationStatus.buyerApproved => 'Aprovado pelo comprador',
      BuyerCollaborationStatus.convertedToOrder => 'Convertido em pedido',
      BuyerCollaborationStatus.expired => 'Expirado',
    };
    return Chip(label: Text(label));
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final BuyerCollaborationComment comment;

  @override
  Widget build(BuildContext context) {
    final authorLabel = comment.authorType == BuyerCollaborationAuthorType.buyer
        ? (comment.authorName ?? 'Comprador')
        : (comment.authorName ?? 'Vendedor');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(authorLabel, style: AppTypography.labelLarge),
              const SizedBox(width: AppSpacing.spacing8),
              if (comment.visibility ==
                  BuyerCollaborationCommentVisibility.internal)
                const Icon(Icons.lock_outline, size: 14),
            ],
          ),
          Text(comment.body),
          if (comment.proposedChanges != null &&
              comment.proposedChanges!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing4),
              child: Text(
                comment.proposedChanges!
                    .map(
                      (change) => switch (change.action) {
                        BuyerCollaborationProposedChangeAction.remove =>
                          'Remover ${change.itemId}',
                        BuyerCollaborationProposedChangeAction.update =>
                          'Alterar ${change.itemId} para ${change.requestedQuantity}',
                        BuyerCollaborationProposedChangeAction.add =>
                          'Adicionar ${change.productName ?? change.itemId}',
                      },
                    )
                    .join(' • '),
                style: AppTypography.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
