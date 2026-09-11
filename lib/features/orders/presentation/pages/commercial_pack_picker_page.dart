import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/utils/utils.dart';
import '../../../commercial_packs/domain/entities/commercial_pack.dart';
import '../../../commercial_packs/domain/entities/commercial_pack_availability.dart';
import '../../../commercial_packs/domain/entities/pack_component.dart';
import '../../../commercial_packs/domain/value_objects/commercial_pack_type.dart';
import '../../../commercial_packs/domain/value_objects/pack_component_composition_type.dart';
import '../bloc/commercial_pack_addition_cubit.dart';
import '../bloc/commercial_pack_addition_state.dart';
import '../bloc/commercial_pack_eligibility_cubit.dart';
import '../bloc/commercial_pack_eligibility_state.dart';

/// "Adicionar kit/pacote" screen (TASK-208, EPIC-32): lists every
/// `CommercialPack` currently eligible for this order draft's customer
/// context (`ListEligibleCommercialPacksUseCase`), lets the seller review one
/// pack's composition and confirm adding it — expanding it into `OrderItem`s
/// linked by `packGroupId` and persisting them straight onto the draft
/// (`CommercialPackAdditionCubit`), the exact same "persist directly, reload
/// on return" pattern `OrderProductAdditionPage` already sets for plain
/// catalog picks.
///
/// Pops back to the caller with `true` only once a pack was actually added —
/// that is what tells `OrderDraftPage` to reload the draft
/// (`OrderDraftStarted(draftId: ...)`), mirroring
/// `OrderProductAdditionPage.build`'s own listener exactly.
class CommercialPackPickerPage extends StatelessWidget {
  const CommercialPackPickerPage({
    required this.organizationId,
    required this.companyId,
    required this.draftId,
    required this.createEligibilityCubit,
    required this.createAdditionCubit,
    required this.getCommercialPackAvailability,
    this.customerSegment,
    this.channel,
    this.collectionId,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String draftId;
  final CommercialPackEligibilityCubit Function() createEligibilityCubit;
  final CommercialPackAdditionCubit Function() createAdditionCubit;

  /// Resolves how many instances of one pack can currently be sold
  /// (`GetCommercialPackAvailabilityUseCase`) — a nullable-`int?` callback
  /// (never the use case type directly) keeps this widget decoupled from DI
  /// wiring details, same precedent `ProductDetailPage.onAddToOrder` already
  /// sets for a page that only needs a function, not a concrete dependency.
  final Future<AppResult<CommercialPackAvailability>> Function(
    CommercialPack pack,
  )
  getCommercialPackAvailability;

  final String? customerSegment;
  final String? channel;
  final String? collectionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommercialPackEligibilityCubit>(
      create: (_) {
        final cubit = createEligibilityCubit();
        unawaited(
          cubit.load(
            organizationId: organizationId,
            companyId: companyId,
            customerSegment: customerSegment,
            channel: channel,
            collectionId: collectionId,
          ),
        );
        return cubit;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Adicionar kit ou pacote')),
        body:
            BlocBuilder<
              CommercialPackEligibilityCubit,
              CommercialPackEligibilityState
            >(
              builder: (context, state) {
                switch (state.status) {
                  case CommercialPackEligibilityStatus.initial:
                  case CommercialPackEligibilityStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case CommercialPackEligibilityStatus.failure:
                    return AppErrorState(
                      title: 'Não foi possível carregar os kits/pacotes',
                      message:
                          state.failure?.message ?? 'Tente novamente em breve.',
                      retryLabel: 'Tentar novamente',
                      onRetry: () =>
                          context.read<CommercialPackEligibilityCubit>().load(
                            organizationId: organizationId,
                            companyId: companyId,
                            customerSegment: customerSegment,
                            channel: channel,
                            collectionId: collectionId,
                          ),
                    );
                  case CommercialPackEligibilityStatus.success:
                    if (state.packs.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: 'Nenhum kit ou pacote disponível',
                        description:
                            'Não há kits, pacotes ou sortimentos elegíveis para '
                            'este cliente agora.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.spacing16),
                      itemCount: state.packs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.spacing8),
                      itemBuilder: (context, index) => _CommercialPackTile(
                        pack: state.packs[index],
                        getAvailability: getCommercialPackAvailability,
                        onTap: () => unawaited(
                          _openCompositionSheet(context, state.packs[index]),
                        ),
                      ),
                    );
                }
              },
            ),
      ),
    );
  }

  Future<void> _openCompositionSheet(
    BuildContext context,
    CommercialPack pack,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider<CommercialPackAdditionCubit>(
        create: (_) => createAdditionCubit(),
        child: _CommercialPackCompositionSheet(
          pack: pack,
          organizationId: organizationId,
          companyId: companyId,
          draftId: draftId,
          customerSegment: customerSegment,
          channel: channel,
        ),
      ),
    );
  }
}

class _CommercialPackTile extends StatelessWidget {
  const _CommercialPackTile({
    required this.pack,
    required this.getAvailability,
    required this.onTap,
  });

  final CommercialPack pack;
  final Future<AppResult<CommercialPackAvailability>> Function(
    CommercialPack pack,
  )
  getAvailability;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.radius8),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
          border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pack.name,
                    style: AppTypography.bodyLarge.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    '${_typeLabel(pack.packType)} · ${pack.components.length} '
                    'componente(s)',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  FutureBuilder<AppResult<CommercialPackAvailability>>(
                    future: getAvailability(pack),
                    builder: (context, snapshot) {
                      final availability = snapshot.data;
                      if (availability == null) {
                        return const SizedBox.shrink();
                      }
                      return switch (availability) {
                        AppSuccess<CommercialPackAvailability>(
                          value: final value,
                        ) =>
                          value.isFullyAvailable
                              ? AppStatusBadge(
                                  label:
                                      '${value.availableInstances} '
                                      'disponíveis',
                                  variant: AppStatusBadgeVariant.success,
                                  icon: Icons.check_circle_outline,
                                )
                              : const AppStatusBadge(
                                  label: 'Estoque insuficiente',
                                  variant: AppStatusBadgeVariant.warning,
                                  icon: Icons.warning_amber_outlined,
                                ),
                        AppFailure<CommercialPackAvailability>() =>
                          const SizedBox.shrink(),
                      };
                    },
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _typeLabel(CommercialPackType type) {
    return switch (type) {
      CommercialPackType.kit => 'Kit',
      CommercialPackType.pack => 'Pacote',
      CommercialPackType.assortment => 'Sortimento',
    };
  }
}

/// Composition review + confirmation for one `CommercialPack` (TASK-208).
/// Shows every component with its own quantity rule, lets the seller adjust
/// a `flexible` component's quantity within `PackComponent.minQuantity`/
/// `maxQuantity`, and — only when at least one component uses
/// `gridProportion` — asks for the "peças totais do sortimento" every
/// proportion is a fraction of.
class _CommercialPackCompositionSheet extends StatefulWidget {
  const _CommercialPackCompositionSheet({
    required this.pack,
    required this.organizationId,
    required this.companyId,
    required this.draftId,
    this.customerSegment,
    this.channel,
  });

  final CommercialPack pack;
  final String organizationId;
  final String companyId;
  final String draftId;
  final String? customerSegment;
  final String? channel;

  @override
  State<_CommercialPackCompositionSheet> createState() =>
      _CommercialPackCompositionSheetState();
}

class _CommercialPackCompositionSheetState
    extends State<_CommercialPackCompositionSheet> {
  final Map<String, int> _quantityOverridesByComponent = <String, int>{};
  int _totalGridQuantity = 10;

  bool get _hasGridProportionComponent => widget.pack.components.any(
    (component) =>
        component.compositionType ==
        PackComponentCompositionType.gridProportion,
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocConsumer<
      CommercialPackAdditionCubit,
      CommercialPackAdditionState
    >(
      listener: (context, state) {
        switch (state.status) {
          case CommercialPackAdditionStatus.success:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${widget.pack.name} adicionado ao pedido.'),
              ),
            );
            context.pop();
          case CommercialPackAdditionStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.failure?.message ??
                      'Não foi possível adicionar este kit/pacote agora.',
                ),
              ),
            );
          case CommercialPackAdditionStatus.idle:
          case CommercialPackAdditionStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(widget.pack.name, style: AppTypography.titleLarge),
                  if (widget.pack.description != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      widget.pack.description!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spacing16),
                  Text('Composição', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.spacing8),
                  for (final component in widget.pack.components)
                    _ComponentRow(
                      component: component,
                      quantity: _quantityOverridesByComponent[component.id],
                      onQuantityChanged: (quantity) => setState(
                        () => _quantityOverridesByComponent[component.id] =
                            quantity,
                      ),
                    ),
                  if (_hasGridProportionComponent) ...<Widget>[
                    const SizedBox(height: AppSpacing.spacing16),
                    Text(
                      'Total de peças do sortimento',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing8),
                    AppQuantityStepper(
                      quantity: _totalGridQuantity,
                      minQuantity: 1,
                      semanticLabel: 'Total de peças do sortimento',
                      onChanged: (quantity) =>
                          setState(() => _totalGridQuantity = quantity),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spacing8),
                  Text(
                    'Preço, desconto e disponibilidade definitivos serão '
                    'revalidados pelo servidor antes do envio do pedido.',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  AppButton(
                    label: 'Adicionar ao pedido',
                    leadingIcon: Icons.add_box_outlined,
                    isLoading:
                        state.status == CommercialPackAdditionStatus.submitting,
                    onPressed:
                        state.status == CommercialPackAdditionStatus.submitting
                        ? null
                        : () => unawaited(
                            context.read<CommercialPackAdditionCubit>().add(
                              organizationId: widget.organizationId,
                              companyId: widget.companyId,
                              draftId: widget.draftId,
                              pack: widget.pack,
                              customerChannel: widget.channel,
                              customerSegment: widget.customerSegment,
                              quantityOverridesByComponent:
                                  _quantityOverridesByComponent,
                              totalGridQuantity: _hasGridProportionComponent
                                  ? _totalGridQuantity
                                  : null,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.component,
    required this.quantity,
    required this.onQuantityChanged,
  });

  final PackComponent component;
  final int? quantity;
  final ValueChanged<int> onQuantityChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isFlexible =
        component.compositionType == PackComponentCompositionType.flexible;
    final description = switch (component.compositionType) {
      PackComponentCompositionType.fixed => '${component.quantity} un. · fixo',
      PackComponentCompositionType.flexible =>
        'De ${component.minQuantity} a ${component.maxQuantity} un.',
      PackComponentCompositionType.gridProportion =>
        '${((component.proportion ?? 0) * 100).toStringAsFixed(0)}% do '
            'total',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  component.scopeReferenceId,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
          if (isFlexible)
            AppQuantityStepper(
              quantity: quantity ?? (component.minQuantity ?? 0),
              minQuantity: component.minQuantity ?? 0,
              maxQuantity: component.maxQuantity,
              semanticLabel: 'Quantidade do componente',
              onChanged: onQuantityChanged,
            ),
        ],
      ),
    );
  }
}
