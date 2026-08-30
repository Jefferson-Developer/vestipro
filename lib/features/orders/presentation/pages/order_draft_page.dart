import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../customers/customers.dart';
import '../../domain/entities/order.dart';
import '../bloc/order_draft_bloc.dart';
import '../bloc/order_draft_event.dart';
import '../bloc/order_draft_state.dart';

/// "Novo pedido" screen (EPIC-13, TASK-096): seller picks a customer from
/// their carteira, the resulting `Order` draft is created and persisted
/// 100% offline, and every further edit (notes today) autosaves with a
/// visible pending/saving/saved/failed indicator — never silently.
class OrderDraftPage extends StatelessWidget {
  const OrderDraftPage({
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.permissionService,
    required this.createBloc,
    required this.createCustomerPortfolioBloc,
    this.draftId,
    this.onContinueToProducts,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final PermissionService permissionService;
  final OrderDraftBloc Function() createBloc;
  final CustomerPortfolioBloc Function() createCustomerPortfolioBloc;

  /// When provided, resumes that exact draft instead of starting from the
  /// customer-picker step.
  final String? draftId;

  /// Called once the seller taps "Adicionar produtos" with the ready
  /// `Order` draft. Left optional (like `CustomerPortfolioPage`'s own
  /// `onCustomerSelected`) so this screen already works end to end before
  /// the product-catalog step (TASK-097, EPIC-13) exists to wire it to.
  final void Function(Order order)? onContinueToProducts;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: sellerId,
      capability: Capability.orderCreate,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<OrderDraftBloc>(
          create: (_) => createBloc()
            ..add(
              OrderDraftStarted(
                organizationId: organizationId,
                companyId: companyId,
                sellerId: sellerId,
                draftId: draftId,
              ),
            ),
          child: _OrderDraftView(
            organizationId: organizationId,
            companyId: companyId,
            sellerId: sellerId,
            permissionService: permissionService,
            createCustomerPortfolioBloc: createCustomerPortfolioBloc,
            onContinueToProducts: onContinueToProducts,
          ),
        );
      },
    );
  }
}

class _OrderDraftView extends StatelessWidget {
  const _OrderDraftView({
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    required this.permissionService,
    required this.createCustomerPortfolioBloc,
    this.onContinueToProducts,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final PermissionService permissionService;
  final CustomerPortfolioBloc Function() createCustomerPortfolioBloc;
  final void Function(Order order)? onContinueToProducts;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderDraftBloc, OrderDraftState>(
      // Starting a draft for a picked customer can fail (permission denied,
      // no active branch/price list/payment term configured) while staying
      // in `awaitingCustomer` so the seller can just pick another customer
      // — that failure must still never be silent (AGENTS.md), so it is
      // surfaced here as a snackbar instead of losing it.
      listenWhen: (previous, current) =>
          current.loadStatus == OrderDraftLoadStatus.awaitingCustomer &&
          current.failure != null &&
          previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      builder: (context, state) {
        if (state.loadStatus == OrderDraftLoadStatus.awaitingCustomer) {
          // Reuses the carteira search/filters/pagination as-is (TASK-051)
          // instead of a second customer-search implementation — a customer
          // outside the seller's carteira never appears here to begin with.
          return CustomerPortfolioPage(
            organizationId: organizationId,
            companyId: companyId,
            userId: sellerId,
            permissionService: permissionService,
            createBloc: createCustomerPortfolioBloc,
            onCustomerSelected: (customer) => context
                .read<OrderDraftBloc>()
                .add(OrderDraftCustomerSelected(customer)),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Novo pedido')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, OrderDraftState state) {
    switch (state.loadStatus) {
      case OrderDraftLoadStatus.initial:
      case OrderDraftLoadStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case OrderDraftLoadStatus.failure:
        return AppErrorState(
          title: 'Não foi possível iniciar o pedido',
          message: state.failure?.message ?? 'Tente novamente em breve.',
          retryLabel: 'Tentar novamente',
          onRetry: () => context.read<OrderDraftBloc>().add(
            OrderDraftStarted(
              organizationId: organizationId,
              companyId: companyId,
              sellerId: sellerId,
            ),
          ),
        );
      case OrderDraftLoadStatus.ready:
        return _OrderDraftSummary(
          state: state,
          onContinueToProducts: onContinueToProducts,
        );
      case OrderDraftLoadStatus.awaitingCustomer:
        // Handled by `_OrderDraftView.build` itself before reaching here.
        return const SizedBox.shrink();
    }
  }
}

class _OrderDraftSummary extends StatefulWidget {
  const _OrderDraftSummary({required this.state, this.onContinueToProducts});

  final OrderDraftState state;
  final void Function(Order order)? onContinueToProducts;

  @override
  State<_OrderDraftSummary> createState() => _OrderDraftSummaryState();
}

class _OrderDraftSummaryState extends State<_OrderDraftSummary> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(
      text: widget.state.order?.notes ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _OrderDraftSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    final notes = widget.state.order?.notes ?? '';
    if (_notesController.text != notes) {
      _notesController.text = notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.state.order;
    if (order == null) return const SizedBox.shrink();
    final defaults = widget.state.defaults;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Resumo do pedido', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.spacing16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.radius8),
              border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SummaryRow(label: 'Cliente', value: order.customerId),
                _SummaryRow(
                  label: 'Unidade',
                  value: defaults?.branch.name ?? order.branchId,
                ),
                _SummaryRow(
                  label: 'Tabela de preço',
                  value: defaults?.priceList.name ?? order.priceListId,
                ),
                _SummaryRow(
                  label: 'Condição de pagamento',
                  value: defaults?.paymentTerm.name ?? order.paymentTermId,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _notesController,
            label: 'Observação',
            hintText: 'Observações do pedido (opcional)',
            semanticLabel: 'Observação do pedido',
            maxLines: 3,
            onChanged: (value) => context.read<OrderDraftBloc>().add(
              OrderDraftNotesChanged(value),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          _AutoSaveIndicator(state: widget.state),
          const SizedBox(height: AppSpacing.spacing24),
          AppButton(
            label: 'Adicionar produtos',
            leadingIcon: Icons.add_shopping_cart_outlined,
            onPressed: widget.onContinueToProducts == null
                ? null
                : () => widget.onContinueToProducts!(order),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutoSaveIndicator extends StatelessWidget {
  const _AutoSaveIndicator({required this.state});

  final OrderDraftState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.saveStatus) {
      OrderDraftSaveStatus.idle => const SizedBox.shrink(),
      OrderDraftSaveStatus.saving => const AppStatusBadge(
        label: 'Salvando...',
        variant: AppStatusBadgeVariant.info,
        icon: Icons.cloud_sync_outlined,
      ),
      OrderDraftSaveStatus.saved => const AppStatusBadge(
        label: 'Rascunho salvo',
        variant: AppStatusBadgeVariant.success,
        icon: Icons.check_circle_outline,
      ),
      OrderDraftSaveStatus.failure => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const AppStatusBadge(
            label: 'Falha ao salvar o rascunho',
            variant: AppStatusBadgeVariant.error,
            icon: Icons.error_outline,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          AppButton(
            label: 'Tentar novamente',
            variant: AppButtonVariant.text,
            onPressed: () => context.read<OrderDraftBloc>().add(
              const OrderDraftAutoSaveRetried(),
            ),
          ),
        ],
      ),
    };
  }
}
