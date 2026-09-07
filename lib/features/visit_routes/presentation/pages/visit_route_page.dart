import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../customers/domain/services/customer_map_pin_builder.dart';
import '../../../customers/domain/value_objects/geo_coordinates.dart';
import '../../../customers/presentation/bloc/customer_portfolio_bloc.dart';
import '../../../customers/presentation/bloc/customer_portfolio_event.dart';
import '../../../customers/presentation/bloc/customer_portfolio_state.dart';
import '../../domain/entities/visit_route_stop.dart';
import '../../domain/services/navigation_link_builder.dart';
import '../../domain/value_objects/navigation_provider.dart';
import '../bloc/visit_route_bloc.dart';
import '../bloc/visit_route_event.dart';
import '../bloc/visit_route_state.dart';
import '../widgets/visit_route_map_preview.dart';
import '../widgets/visit_route_stop_tile.dart';

/// Roteirização de visitas (TASK-177, EPIC-24): the seller picks customers
/// from their own portfolio (already geocoded — see `CustomerMapPinBuilder`)
/// and gets an optimized visit order for the day, reorderable, with
/// distance/eta estimates and one tap to open external navigation for any
/// stop.
class VisitRoutePage extends StatelessWidget {
  const VisitRoutePage({
    required this.organizationId,
    required this.companyId,
    required this.salesRepId,
    required this.permissionService,
    required this.createBloc,
    required this.createPortfolioBloc,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String salesRepId;
  final PermissionService permissionService;
  final VisitRouteBloc Function() createBloc;
  final CustomerPortfolioBloc Function() createPortfolioBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: salesRepId,
      capability: Capability.customerView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return MultiBlocProvider(
          providers: [
            BlocProvider<VisitRouteBloc>(
              create: (_) => createBloc()
                ..add(
                  VisitRouteStarted(
                    organizationId: organizationId,
                    companyId: companyId,
                    salesRepId: salesRepId,
                  ),
                ),
            ),
            BlocProvider<CustomerPortfolioBloc>(
              create: (_) => createPortfolioBloc()
                ..add(
                  CustomerPortfolioStarted(
                    organizationId: organizationId,
                    companyId: companyId,
                    userId: salesRepId,
                  ),
                ),
            ),
          ],
          child: const _VisitRouteScaffold(),
        );
      },
    );
  }
}

class _VisitRouteScaffold extends StatelessWidget {
  const _VisitRouteScaffold();

  static const _pinBuilder = CustomerMapPinBuilder();
  static const _navigationLinkBuilder = NavigationLinkBuilder();

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerPortfolioBloc, CustomerPortfolioState>(
      listenWhen: (previous, current) =>
          previous.customers != current.customers,
      listener: (context, state) {
        context.read<VisitRouteBloc>().add(
          VisitRouteAvailablePinsChanged(_pinBuilder.build(state.customers)),
        );
      },
      child: BlocBuilder<VisitRouteBloc, VisitRouteState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.hasRoute
                    ? 'Rota do dia'
                    : 'Selecionar clientes para roteirizar',
              ),
              actions: <Widget>[
                if (state.hasRoute)
                  AppIconButton(
                    icon: Icons.edit_location_alt_outlined,
                    semanticLabel: 'Selecionar outros clientes',
                    onPressed: () => context.read<VisitRouteBloc>().add(
                      const VisitRouteSelectionReopened(),
                    ),
                  ),
              ],
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.hasRoute
                ? _RouteView(
                    stops: state.route!.stops,
                    onNavigate: (stop) =>
                        _openNavigation(context, stop.coordinates),
                    onToggleStatus: (stop) => context
                        .read<VisitRouteBloc>()
                        .add(VisitRouteStopStatusToggled(stop.customerId)),
                    onReorder: (orderedIds) => context
                        .read<VisitRouteBloc>()
                        .add(VisitRouteStopsReordered(orderedIds)),
                  )
                : _SelectionView(state: state),
          );
        },
      ),
    );
  }

  Future<void> _openNavigation(
    BuildContext context,
    GeoCoordinates destination,
  ) async {
    final provider = await AppBottomSheet.show<NavigationProvider>(
      context: context,
      title: 'Abrir navegação',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: NavigationProvider.values
            .map(
              (provider) => ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(provider.label),
                onTap: () => Navigator.of(sheetContext).pop(provider),
              ),
            )
            .toList(growable: false),
      ),
    );
    if (provider == null) return;
    final uri = _navigationLinkBuilder.build(
      provider: provider,
      destination: destination,
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SelectionView extends StatelessWidget {
  const _SelectionView({required this.state});

  final VisitRouteState state;

  @override
  Widget build(BuildContext context) {
    if (state.availablePins.isEmpty) {
      return const AppEmptyState(
        title: 'Nenhum cliente geocodificado disponível',
        description:
            'Clientes precisam de um endereço geocodificado para entrar em '
            'uma rota. Verifique a carteira ou aguarde a geocodificação.',
        icon: Icons.map_outlined,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            itemCount: state.availablePins.length,
            itemBuilder: (context, index) {
              final pin = state.availablePins[index];
              final selected = state.selectedCustomerIds.contains(
                pin.customerId,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                child: AppCheckbox(
                  value: selected,
                  label: pin.displayName,
                  semanticLabel: 'Selecionar ${pin.displayName} para a rota',
                  onChanged: (_) => context.read<VisitRouteBloc>().add(
                    VisitRouteCustomerSelectionToggled(pin.customerId),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing16),
          child: AppButton(
            label:
                'Gerar rota (${state.selectedCustomerIds.length} '
                'selecionados)',
            leadingIcon: Icons.alt_route,
            onPressed: state.selectedCustomerIds.isEmpty
                ? null
                : () => context.read<VisitRouteBloc>().add(
                    const VisitRouteBuildRequested(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RouteView extends StatelessWidget {
  const _RouteView({
    required this.stops,
    required this.onNavigate,
    required this.onToggleStatus,
    required this.onReorder,
  });

  final List<VisitRouteStop> stops;
  final ValueChanged<VisitRouteStop> onNavigate;
  final ValueChanged<VisitRouteStop> onToggleStatus;
  final ValueChanged<List<String>> onReorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: VisitRouteMapPreview(stops: stops),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing16,
            ),
            itemCount: stops.length,
            onReorderItem: (oldIndex, newIndex) {
              final reordered = List<VisitRouteStop>.of(stops);
              final moved = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, moved);
              onReorder(
                reordered
                    .map((stop) => stop.customerId)
                    .toList(growable: false),
              );
            },
            itemBuilder: (context, index) {
              final stop = stops[index];
              return Padding(
                key: ValueKey(stop.customerId),
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                child: VisitRouteStopTile(
                  stop: stop,
                  onNavigate: () => onNavigate(stop),
                  onToggleStatus: () => onToggleStatus(stop),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
