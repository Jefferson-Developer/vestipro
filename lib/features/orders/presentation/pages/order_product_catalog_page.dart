import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../barcode_scanner/barcode_scanner.dart';
import '../../../catalog/catalog.dart';
import '../../../products/domain/entities/product.dart';
import '../bloc/order_items_counter_cubit.dart';
import '../widgets/order_items_counter_indicator.dart';

/// Catalog browsing screen scoped to an in-progress `Order` draft
/// (TASK-097, EPIC-13): reuses `CatalogFilterPage` (TASK-082) as-is for the
/// actual grid/filters — no product-listing logic is duplicated here — and
/// overlays the "N produtos no pedido atual" indicator this task requires,
/// B2B-worded on purpose (never "carrinho"/"sacola").
///
/// Owns its own navigation to [OrderProductDetailRoute] and back, same
/// "feature pushes its own typed `AppRoute`" precedent
/// `sign_up_form.dart`/`TermsOfServiceRoute` already sets: tapping a product
/// pushes the detail route and, once it pops back having actually persisted
/// items, reloads the counter; tapping the indicator itself just pops back
/// to the draft summary.
class OrderProductCatalogPage extends StatelessWidget {
  const OrderProductCatalogPage({
    required this.organizationId,
    required this.companyId,
    required this.draftId,
    required this.createCatalogFilterBloc,
    required this.createItemsCounterCubit,
    required this.createBarcodeScanCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String draftId;
  final CatalogFilterBloc Function() createCatalogFilterBloc;
  final OrderItemsCounterCubit Function() createItemsCounterCubit;

  /// TASK-216: powers the "escanear código" action below — kept as its own
  /// factory (same "bootstrap builds it via `getIt`, this page never calls
  /// `GetIt` itself" shape every other `create...` param on this page
  /// already follows) so this page stays trivially testable without a real
  /// camera/platform channel.
  final BarcodeScanCubit Function() createBarcodeScanCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderItemsCounterCubit>(
      create: (_) {
        final cubit = createItemsCounterCubit();
        unawaited(
          cubit.load(
            organizationId: organizationId,
            companyId: companyId,
            draftId: draftId,
          ),
        );
        return cubit;
      },
      child: Stack(
        children: <Widget>[
          CatalogFilterPage(
            organizationId: organizationId,
            companyId: companyId,
            title: 'Adicionar produtos ao pedido',
            createBloc: createCatalogFilterBloc,
            onProductSelected: (product) =>
                _openProductDetail(context, product),
          ),
          Positioned(
            right: AppSpacing.spacing16,
            bottom: AppSpacing.spacing64 + AppSpacing.spacing24,
            child: AppIconButton(
              icon: Icons.qr_code_scanner,
              semanticLabel: 'Escanear código de barras ou QR do produto',
              variant: AppButtonVariant.primary,
              onPressed: () => _openScanner(context),
            ),
          ),
          Positioned(
            left: AppSpacing.spacing16,
            right: AppSpacing.spacing16,
            bottom: AppSpacing.spacing16,
            child: OrderItemsCounterIndicator(onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }

  Future<void> _openProductDetail(BuildContext context, Product product) {
    return _pushProductDetailAndReload(context, product.id);
  }

  /// Opens TASK-216's scanner sheet and, on a resolved match, pushes the
  /// exact same [OrderProductDetailRoute] [_openProductDetail] pushes for a
  /// tapped catalog card — the scanner only ever identifies *which*
  /// product/variant, it never adds an `OrderItem` or touches price/stock
  /// itself, so every commercial rule that route already enforces
  /// (availability, resolved price, RBAC) applies unchanged here too.
  Future<void> _openScanner(BuildContext context) async {
    final resolution = await BarcodeScannerPage.open(
      context,
      organizationId: organizationId,
      createCubit: createBarcodeScanCubit,
      title: 'Escanear produto para o pedido',
    );
    final productId = resolution?.productId;
    if (productId == null || !context.mounted) return;
    await _pushProductDetailAndReload(context, productId);
  }

  Future<void> _pushProductDetailAndReload(
    BuildContext context,
    String productId,
  ) async {
    final added = await context.push<bool>(
      OrderProductDetailRoute(
        orgId: organizationId,
        companyId: companyId,
        draftId: draftId,
        productId: productId,
      ).location,
    );
    if (added != true || !context.mounted) return;
    unawaited(
      context.read<OrderItemsCounterCubit>().load(
        organizationId: organizationId,
        companyId: companyId,
        draftId: draftId,
      ),
    );
  }
}
