import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../bloc/report_builder_bloc.dart';
import '../bloc/report_builder_event.dart';
import '../bloc/report_builder_state.dart';

class ReportBuilderPage extends StatelessWidget {
  const ReportBuilderPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final ReportBuilderBloc Function() createBloc;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc()
      ..add(
        ReportBuilderStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      ),
    child: const _ReportBuilderView(),
  );
}

class _ReportBuilderView extends StatelessWidget {
  const _ReportBuilderView();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Construtor de relatórios')),
    body: BlocConsumer<ReportBuilderBloc, ReportBuilderState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.failure!.message))),
      builder: (context, state) {
        if (state.status == ReportBuilderStatus.loading ||
            state.status == ReportBuilderStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == ReportBuilderStatus.failure) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.failure?.message ??
                      'Não foi possível abrir o construtor.',
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.read<ReportBuilderBloc>().add(
                    const ReportBuilderRetried(),
                  ),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }
        return _BuilderContent(state: state);
      },
    ),
  );
}

class _BuilderContent extends StatelessWidget {
  const _BuilderContent({required this.state});
  final ReportBuilderState state;

  @override
  Widget build(BuildContext context) {
    final catalog = state.catalog!;
    final definition = state.definition!;
    final editor = _Editor(
      catalog: catalog,
      definition: definition,
      state: state,
    );
    final preview = _Preview(state: state);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 390,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: editor,
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: preview),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            editor,
            const SizedBox(height: 24),
            SizedBox(height: 420, child: preview),
          ],
        );
      },
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.catalog,
    required this.definition,
    required this.state,
  });
  final ReportCatalog catalog;
  final ReportDefinition definition;
  final ReportBuilderState state;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('1. Dimensões', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: catalog.dimensions
            .map(
              (field) => FilterChip(
                label: Text(field.label),
                selected: definition.dimensions.contains(field.id),
                onSelected: (_) => context.read<ReportBuilderBloc>().add(
                  ReportDimensionToggled(field.id),
                ),
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 20),
      Text('2. Métricas', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: catalog.metrics.map((field) {
          final compatible = definition.dimensions.every(
            (dimension) =>
                field.compatibleDimensions.isEmpty ||
                field.compatibleDimensions.contains(dimension),
          );
          return Tooltip(
            message: compatible
                ? field.label
                : 'Incompatível com a dimensão selecionada',
            child: FilterChip(
              label: Text(field.label),
              selected: definition.metrics.contains(field.id),
              onSelected: compatible
                  ? (_) => context.read<ReportBuilderBloc>().add(
                      ReportMetricToggled(field.id),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      Text('3. Filtros', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      TextFormField(
        key: const Key('report-period-filter'),
        initialValue:
            definition.filters
                .where((item) => item.fieldId == 'period')
                .firstOrNull
                ?.value ??
            _currentMonth(),
        decoration: const InputDecoration(
          labelText: 'Período',
          hintText: 'AAAA-MM',
          prefixIcon: Icon(Icons.calendar_month),
        ),
        onChanged: (value) => context.read<ReportBuilderBloc>().add(
          ReportFilterChanged(
            ReportFilter(fieldId: 'period', operatorId: 'equals', value: value),
          ),
        ),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<ReportComparisonPeriod>(
        initialValue: definition.comparisonPeriod,
        decoration: const InputDecoration(labelText: 'Comparação'),
        items: const [
          DropdownMenuItem(
            value: ReportComparisonPeriod.none,
            child: Text('Sem comparação'),
          ),
          DropdownMenuItem(
            value: ReportComparisonPeriod.previousPeriod,
            child: Text('Período anterior'),
          ),
          DropdownMenuItem(
            value: ReportComparisonPeriod.previousYear,
            child: Text('Ano anterior'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            context.read<ReportBuilderBloc>().add(
              ReportComparisonChanged(value),
            );
          }
        },
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<String?>(
        initialValue: definition.sortBy?.fieldId,
        decoration: const InputDecoration(labelText: 'Ordenar por'),
        items: <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Sem ordenação'),
          ),
          ...<String>[...definition.dimensions, ...definition.metrics].map(
            (id) => DropdownMenuItem<String?>(
              value: id,
              child: Text(catalog.find(id)?.label ?? id),
            ),
          ),
        ],
        onChanged: (value) => context.read<ReportBuilderBloc>().add(
          ReportSortChanged(
            value == null
                ? null
                : ReportSort(
                    fieldId: value,
                    direction: ReportSortDirection.descending,
                  ),
          ),
        ),
      ),
      if (definition.groupBy.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          'Agrupamento: ${definition.groupBy.map((id) => catalog.find(id)?.label ?? id).join(' + ')}',
        ),
      ],
      if (definition.filters.isNotEmpty) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: definition.filters
              .map(
                (filter) => Chip(
                  label: Text('${filter.fieldId}: ${filter.value}'),
                  avatar: const Icon(Icons.filter_alt, size: 18),
                ),
              )
              .toList(),
        ),
      ],
      if (state.validationMessage != null) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            state.validationMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('execute-report'),
          onPressed: state.status == ReportBuilderStatus.executing
              ? null
              : () => context.read<ReportBuilderBloc>().add(
                  const ReportExecutionRequested(),
                ),
          icon: state.status == ReportBuilderStatus.executing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.play_arrow),
          label: const Text('Executar relatório'),
        ),
      ),
    ],
  );

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});
  final ReportBuilderState state;

  @override
  Widget build(BuildContext context) {
    final result = state.preview;
    if (result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.query_stats,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'Selecione ao menos uma dimensão e uma métrica para visualizar o relatório.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    if (result.rows.isEmpty) {
      return const Center(
        child: Text('Nenhum dado encontrado para os filtros escolhidos.'),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: result.columns
              .map((column) => DataColumn(label: Text(column)))
              .toList(),
          rows: result.rows
              .map(
                (row) => DataRow(
                  cells: result.columns
                      .map((column) => DataCell(Text('${row[column] ?? '—'}')))
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
