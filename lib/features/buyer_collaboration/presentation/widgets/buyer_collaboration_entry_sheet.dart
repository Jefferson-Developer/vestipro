import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/buyer_collaboration_item.dart';
import '../../domain/value_objects/buyer_collaboration_source_type.dart';
import '../bloc/buyer_collaboration_cubit.dart';
import '../bloc/buyer_collaboration_state.dart';
import 'buyer_collaboration_panel.dart';

/// Seller-facing entry point (TASK-211) — opened as a bottom sheet from the
/// order draft screen, same precedent [CartShareSheet] (TASK-181) already
/// sets. Unlike that one-shot flow, a `BuyerCollaborationSession` starts in
/// `seller_draft` and stays open for the whole negotiation, so this sheet
/// creates it once and then swaps in [BuyerCollaborationPanel] itself
/// (`role: seller`) for everything that follows — sharing, comments,
/// approval and conversion.
class BuyerCollaborationEntrySheet extends StatefulWidget {
  const BuyerCollaborationEntrySheet({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.priceListId,
    required this.sourceType,
    required this.sourceId,
    required this.items,
    required this.createCubit,
    this.onConvertRequested,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final String priceListId;
  final BuyerCollaborationSourceType sourceType;
  final String sourceId;
  final List<BuyerCollaborationItem> items;
  final BuyerCollaborationCubit Function() createCubit;
  final Future<String?> Function()? onConvertRequested;

  @override
  State<BuyerCollaborationEntrySheet> createState() =>
      _BuyerCollaborationEntrySheetState();
}

class _BuyerCollaborationEntrySheetState
    extends State<BuyerCollaborationEntrySheet> {
  bool _showPrices = false;
  late final BuyerCollaborationCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.createCubit();
  }

  @override
  void dispose() {
    // Safe even after `BuyerCollaborationPanel` (once shown) has already
    // closed this same instance itself — `Cubit.close()` wraps a
    // `StreamController.close()`, which dart:async already guarantees is
    // idempotent.
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BuyerCollaborationCubit>.value(
      value: _cubit,
      child: BlocBuilder<BuyerCollaborationCubit, BuyerCollaborationState>(
        builder: (context, state) {
          if (state.createdSessionId != null) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: BuyerCollaborationPanel(
                organizationId: widget.organizationId,
                sessionId: state.createdSessionId!,
                role: BuyerCollaborationViewerRole.seller,
                createCubit: () => _cubit,
                onConvertRequested: widget.onConvertRequested,
              ),
            );
          }
          final busy =
              state.actionStatus == BuyerCollaborationActionStatus.submitting;
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Colaborar com o comprador',
                  style: AppTypography.titleLarge,
                ),
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  '${widget.items.length} variantes. O comprador poderá '
                  'comentar, pedir ajustes e aprovar antes de virar pedido.',
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exibir preços para o comprador'),
                  value: _showPrices,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => _showPrices = value),
                ),
                if (state.actionFailure != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                    child: Text(
                      state.actionFailure!.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () => context.read<BuyerCollaborationCubit>().create(
                          organizationId: widget.organizationId,
                          companyId: widget.companyId,
                          customerId: widget.customerId,
                          priceListId: widget.priceListId,
                          sourceType: widget.sourceType,
                          sourceId: widget.sourceId,
                          items: widget.items,
                          showPrices: _showPrices,
                        ),
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Abrir colaboração'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
