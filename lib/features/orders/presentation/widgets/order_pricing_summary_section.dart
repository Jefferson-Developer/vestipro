import 'dart:async' show Timer, unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_pricing_summary.dart';
import '../bloc/order_pricing_summary_cubit.dart';
import '../bloc/order_pricing_summary_state.dart';

/// "Resumo comercial do pedido" (EPIC-13, TASK-099): subtotal, desconto,
/// acréscimo, frete e total sempre exatamente como o motor de precificação
/// server-side (`calculatePricing`, TASK-088) devolveu — nunca um cálculo
/// divergente feito aqui. Debounces a recalculation (mirroring
/// `OrderDraftBloc.autoSaveDebounce`'s own token-based debounce) every time
/// [order]'s items/priceList/paymentTerm/shipping change, so a seller typing
/// through several grid cells in a row triggers one recalculation, not one
/// per keystroke — and, since this owns its own `OrderPricingSummaryCubit`
/// instance separate from `OrderDraftBloc`, that recalculation never blocks
/// editing quantities elsewhere on the same screen while it is in flight.
class OrderPricingSummarySection extends StatefulWidget {
  const OrderPricingSummarySection({
    required this.order,
    required this.createCubit,
    super.key,
  });

  final Order order;
  final OrderPricingSummaryCubit Function() createCubit;

  @override
  State<OrderPricingSummarySection> createState() =>
      _OrderPricingSummarySectionState();
}

class _OrderPricingSummarySectionState
    extends State<OrderPricingSummarySection> {
  static const _recalculateDebounce = Duration(milliseconds: 500);

  late final OrderPricingSummaryCubit _cubit;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _cubit = widget.createCubit();
    _scheduleRecalculate();
  }

  @override
  void didUpdateWidget(covariant OrderPricingSummarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_pricingRelevantFieldsChanged(oldWidget.order, widget.order)) {
      _scheduleRecalculate();
    }
  }

  bool _pricingRelevantFieldsChanged(Order previous, Order current) {
    if (previous.priceListId != current.priceListId ||
        previous.paymentTermId != current.paymentTermId ||
        previous.shippingAmount != current.shippingAmount ||
        previous.items.length != current.items.length) {
      return true;
    }
    for (var index = 0; index < current.items.length; index++) {
      final previousItem = previous.items[index];
      final currentItem = current.items[index];
      if (previousItem.variantId != currentItem.variantId ||
          previousItem.quantity != currentItem.quantity ||
          previousItem.unitPrice != currentItem.unitPrice) {
        return true;
      }
    }
    return false;
  }

  void _scheduleRecalculate() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_recalculateDebounce, () {
      unawaited(_cubit.recalculate(widget.order));
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    unawaited(_cubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderPricingSummaryCubit>.value(
      value: _cubit,
      child: BlocBuilder<OrderPricingSummaryCubit, OrderPricingSummaryState>(
        builder: (context, state) =>
            _OrderPricingSummaryCardContent(state: state),
      ),
    );
  }
}

class _OrderPricingSummaryCardContent extends StatelessWidget {
  const _OrderPricingSummaryCardContent({required this.state});

  final OrderPricingSummaryState state;

  static const _title = 'Resumo comercial';

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case OrderPricingSummaryStatus.initial:
        return const SizedBox.shrink();

      case OrderPricingSummaryStatus.recalculating:
        final summary = state.summary;
        if (summary == null) {
          return const AppSkeleton(height: 160);
        }
        return AppCommercialSummaryCard(
          title: _title,
          statusBadge: const AppStatusBadge(
            label: 'Recalculando...',
            variant: AppStatusBadgeVariant.info,
            icon: Icons.sync,
          ),
          lines: _linesFor(summary),
        );

      case OrderPricingSummaryStatus.success:
        final summary = state.summary!;
        return AppCommercialSummaryCard(
          title: _title,
          statusBadge: _statusBadgeFor(summary),
          lines: _linesFor(summary),
        );

      case OrderPricingSummaryStatus.offlineEstimate:
        return AppCommercialSummaryCard(
          title: _title,
          statusBadge: const AppStatusBadge(
            label: 'Estimativa não confirmada',
            variant: AppStatusBadgeVariant.warning,
            icon: Icons.cloud_off_outlined,
          ),
          lines: <AppCommercialSummaryLine>[
            AppCommercialSummaryLine(
              label: 'Subtotal',
              value: _formatCurrency(state.localEstimateSubtotal ?? 0),
            ),
            AppCommercialSummaryLine(
              label: 'Frete',
              value: _formatCurrency(state.localEstimateShippingAmount ?? 0),
            ),
            AppCommercialSummaryLine(
              label: 'Total (estimativa local)',
              value: _formatCurrency(state.localEstimateTotal ?? 0),
              emphasis: true,
            ),
          ],
          footnote:
              'Sem conexão com o motor de precificação: este total ainda '
              'não foi confirmado (sem desconto/acréscimo aplicado) e pode '
              'mudar assim que o pedido sincronizar.',
        );

      case OrderPricingSummaryStatus.failure:
        return AppErrorState(
          title: 'Não foi possível calcular o resumo comercial',
          message: state.failure?.message ?? 'Tente novamente em breve.',
        );
    }
  }

  /// Signals — never hides — a manual discount above the seller's policy
  /// (`approvalRequired`) or one the policy outright blocks (`blocked`),
  /// exactly as `calculatePricing` reported them (TASK-099's "descontos
  /// acima do limite do perfil devem ser sinalizados... nunca escondidos"
  /// rule).
  Widget? _statusBadgeFor(OrderPricingSummary summary) {
    if (summary.blocked) {
      return const AppStatusBadge(
        label: 'Desconto bloqueado',
        variant: AppStatusBadgeVariant.error,
        icon: Icons.block_outlined,
      );
    }
    if (summary.approvalRequired) {
      return const AppStatusBadge(
        label: 'Desconto exige aprovação',
        variant: AppStatusBadgeVariant.warning,
        icon: Icons.rule_folder_outlined,
      );
    }
    return null;
  }

  List<AppCommercialSummaryLine> _linesFor(OrderPricingSummary summary) {
    final lines = <AppCommercialSummaryLine>[
      AppCommercialSummaryLine(
        label: 'Subtotal',
        value: _formatCurrency(summary.subtotal),
      ),
    ];
    if (summary.discountTotal > 0) {
      lines.add(
        AppCommercialSummaryLine(
          label: 'Desconto',
          value: '- ${_formatCurrency(summary.discountTotal)}',
          tone: AppCommercialSummaryLineTone.positive,
        ),
      );
    }
    if (summary.paymentTermAdjustmentTotal != 0) {
      lines.add(
        AppCommercialSummaryLine(
          label: 'Acréscimo',
          value: _formatCurrency(summary.paymentTermAdjustmentTotal),
          tone: AppCommercialSummaryLineTone.negative,
        ),
      );
    }
    lines
      ..add(
        AppCommercialSummaryLine(
          label: 'Frete',
          value: _formatCurrency(summary.shippingAmount),
        ),
      )
      ..add(
        AppCommercialSummaryLine(
          label: 'Total',
          value: _formatCurrency(summary.total),
          emphasis: true,
        ),
      );
    return lines;
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  ).format(value);
}
