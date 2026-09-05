import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/geographic_dashboard_filters.dart';
import '../../domain/entities/geographic_dashboard_snapshot.dart';
import '../bloc/geographic_dashboard_bloc.dart';
import '../bloc/geographic_dashboard_event.dart';
import '../bloc/geographic_dashboard_state.dart';

class GeographicDashboardPage extends StatelessWidget {
  const GeographicDashboardPage({
    super.key,
    required this.organizationId,
    required this.userId,
    required this.initialFilters,
    required this.createBloc,
    required this.onOpenCustomers,
    required this.onOpenOrders,
    this.onFiltersChanged,
  });
  final String organizationId;
  final String userId;
  final GeographicDashboardFilters initialFilters;
  final GeographicDashboardBloc Function() createBloc;
  final ValueChanged<List<String>> onOpenCustomers;
  final ValueChanged<List<String>> onOpenOrders;
  final ValueChanged<GeographicDashboardFilters>? onFiltersChanged;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc()
      ..add(
        GeographicDashboardStarted(
          organizationId: organizationId,
          userId: userId,
          filters: initialFilters,
        ),
      ),
    child: _View(onOpenCustomers: onOpenCustomers, onOpenOrders: onOpenOrders),
  );
}

class _View extends StatelessWidget {
  const _View({required this.onOpenCustomers, required this.onOpenOrders});
  final ValueChanged<List<String>> onOpenCustomers;
  final ValueChanged<List<String>> onOpenOrders;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard geográfico')),
    body: BlocBuilder<GeographicDashboardBloc, GeographicDashboardState>(
      builder: (context, state) => switch (state.status) {
        GeographicDashboardStatus.initial ||
        GeographicDashboardStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        GeographicDashboardStatus.forbidden => const AppEmptyState(
          icon: Icons.lock_outline,
          title: 'Dados geográficos sem acesso',
          description:
              'Este recorte está fora da sua responsabilidade comercial.',
        ),
        GeographicDashboardStatus.failure => AppErrorState(
          title: 'Não foi possível carregar o dashboard',
          message: state.failure?.message ?? 'Tente novamente.',
          retryLabel: 'Tentar novamente',
          onRetry: () => context.read<GeographicDashboardBloc>().add(
            const GeographicDashboardRetried(),
          ),
        ),
        GeographicDashboardStatus.ready => _Content(
          snapshot: state.snapshot!,
          onSelect: (row) => context.read<GeographicDashboardBloc>().add(
            GeographicDashboardDrillDownRequested(row),
          ),
          onOpenCustomers: onOpenCustomers,
          onOpenOrders: onOpenOrders,
        ),
      },
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({
    required this.snapshot,
    required this.onSelect,
    required this.onOpenCustomers,
    required this.onOpenOrders,
  });
  final GeographicDashboardSnapshot snapshot;
  final ValueChanged<GeographicDashboardRow> onSelect;
  final ValueChanged<List<String>> onOpenCustomers;
  final ValueChanged<List<String>> onOpenOrders;

  @override
  Widget build(BuildContext context) {
    if (snapshot.regions.isEmpty) {
      return const AppEmptyState(
        icon: Icons.public_off,
        title: 'Sem dados no período',
        description:
            'O ranking aparecerá após o processamento das vendas do período.',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      children: <Widget>[
        if (snapshot.isFromLocalCache)
          const Text('Exibindo o último snapshot disponível offline.'),
        GridView.count(
          key: const Key('geographic-kpis'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width < 700 ? 2 : 4,
          childAspectRatio: 1.7,
          crossAxisSpacing: AppSpacing.spacing12,
          mainAxisSpacing: AppSpacing.spacing12,
          children: <Widget>[
            AppKpiCard(
              label: 'Faturamento',
              value: _currency(snapshot.revenue),
            ),
            AppKpiCard(
              label: 'Clientes ativos',
              value: '${snapshot.activeCustomerCount}',
            ),
            AppKpiCard(
              label: 'Ticket médio',
              value: _currency(snapshot.averageTicket),
            ),
            AppKpiCard(label: 'Pedidos', value: '${snapshot.orderCount}'),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing16),
        if (!snapshot.hasMapData)
          const Card(
            child: ListTile(
              leading: Icon(Icons.map_outlined),
              title: Text('Mapa indisponível'),
              subtitle: Text(
                'O ranking continua disponível; o mapa será exibido quando houver coordenadas agregadas.',
              ),
            ),
          ),
        Text('Ranking por região', style: AppTypography.titleLarge),
        ...snapshot.regions.indexed.map(
          (entry) => _AreaTile(
            rank: entry.$1 + 1,
            row: entry.$2,
            onSelect: onSelect,
            onOpenCustomers: onOpenCustomers,
            onOpenOrders: onOpenOrders,
          ),
        ),
      ],
    );
  }
}

class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.rank,
    required this.row,
    required this.onSelect,
    required this.onOpenCustomers,
    required this.onOpenOrders,
  });
  final int rank;
  final GeographicDashboardRow row;
  final ValueChanged<GeographicDashboardRow> onSelect;
  final ValueChanged<List<String>> onOpenCustomers;
  final ValueChanged<List<String>> onOpenOrders;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      onExpansionChanged: (expanded) {
        if (expanded) onSelect(row);
      },
      leading: CircleAvatar(child: Text('$rank')),
      title: Text(row.label),
      subtitle: Text(
        '${_currency(row.revenue)} • ${row.activeCustomerCount} clientes • ticket ${_currency(row.averageTicket)}${row.topProducts.isEmpty ? '' : ' • Top: ${row.topProducts.first.name}'}',
      ),
      children: <Widget>[
        if (row.children.isNotEmpty)
          ...row.children.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.spacing16),
              child: _AreaTile(
                rank: entry.$1 + 1,
                row: entry.$2,
                onSelect: onSelect,
                onOpenCustomers: onOpenCustomers,
                onOpenOrders: onOpenOrders,
              ),
            ),
          ),
        if (row.children.isEmpty)
          OverflowBar(
            alignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: row.customerIds.isEmpty
                    ? null
                    : () => onOpenCustomers(row.customerIds),
                child: const Text('Ver clientes'),
              ),
              TextButton(
                onPressed: row.orderIds.isEmpty
                    ? null
                    : () => onOpenOrders(row.orderIds),
                child: const Text('Ver pedidos'),
              ),
            ],
          ),
      ],
    ),
  );
}

String _currency(double value) =>
    NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);
