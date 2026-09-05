import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/saved_report.dart';
import '../bloc/report_builder_bloc.dart';
import '../bloc/report_builder_event.dart';
import '../bloc/report_builder_state.dart';
import '../bloc/saved_reports_bloc.dart';
import '../bloc/saved_reports_event.dart';
import '../bloc/saved_reports_state.dart';

class ReportBuilderPage extends StatelessWidget {
  const ReportBuilderPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.createBloc,
    this.createSavedReportsBloc,
    this.permissionService,
    this.onOpenSavedReports,
    super.key,
  }) : assert(
         (createSavedReportsBloc == null) == (permissionService == null),
         'createSavedReportsBloc and permissionService must be provided '
         'together (TASK-145 "Salvar visualização" affordance), or both '
         'omitted.',
       );

  final String organizationId;
  final String companyId;
  final String userId;
  final ReportBuilderBloc Function() createBloc;

  /// When provided (together with [permissionService]), enables the "Salvar
  /// visualização" (TASK-145) app bar action — omitted by callers/tests that
  /// only exercise the plain TASK-144 builder.
  final SavedReportsBloc Function()? createSavedReportsBloc;
  final PermissionService? permissionService;

  /// Navigates to `SavedReportsRoute` ("Meus relatórios"/"Compartilhados
  /// comigo") — only shown alongside [createSavedReportsBloc].
  final VoidCallback? onOpenSavedReports;

  @override
  Widget build(BuildContext context) {
    final view = _ReportBuilderView(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      onOpenSavedReports: onOpenSavedReports,
    );
    final reportBuilderProvider = BlocProvider<ReportBuilderBloc>(
      create: (_) => createBloc()
        ..add(
          ReportBuilderStarted(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
          ),
        ),
      child: view,
    );

    final savedReportsBlocFactory = createSavedReportsBloc;
    if (savedReportsBlocFactory == null) return reportBuilderProvider;

    return BlocProvider<SavedReportsBloc>(
      create: (_) => savedReportsBlocFactory()
        ..add(
          SavedReportsStarted(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
          ),
        ),
      child: reportBuilderProvider,
    );
  }
}

class _ReportBuilderView extends StatelessWidget {
  const _ReportBuilderView({
    required this.permissionService,
    required this.organizationId,
    required this.userId,
    required this.onOpenSavedReports,
  });

  final PermissionService? permissionService;
  final String organizationId;
  final String userId;
  final VoidCallback? onOpenSavedReports;

  @override
  Widget build(BuildContext context) {
    final canSaveReports = permissionService != null;

    Widget body = BlocConsumer<ReportBuilderBloc, ReportBuilderState>(
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
    );

    if (canSaveReports) {
      body = BlocListener<SavedReportsBloc, SavedReportsState>(
        listenWhen: (previous, current) =>
            previous.failure != current.failure ||
            previous.successMessage != current.successMessage,
        listener: (context, state) {
          if (state.failure != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
            context.read<SavedReportsBloc>().add(
              const SavedReportsMessageCleared(),
            );
          } else if (state.successMessage != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
            context.read<SavedReportsBloc>().add(
              const SavedReportsMessageCleared(),
            );
          }
        },
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Construtor de relatórios'),
        actions: canSaveReports
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined),
                  tooltip: 'Salvar visualização',
                  onPressed: () => _showSaveDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open_outlined),
                  tooltip: 'Meus relatórios',
                  onPressed: onOpenSavedReports,
                ),
              ]
            : null,
      ),
      body: body,
    );
  }

  Future<void> _showSaveDialog(BuildContext context) async {
    final definition = context.read<ReportBuilderBloc>().state.definition;
    if (definition == null) return;

    final result = await showDialog<_SaveReportRequest>(
      context: context,
      builder: (dialogContext) => _SaveReportDialog(
        permissionService: permissionService!,
        organizationId: organizationId,
        userId: userId,
      ),
    );
    if (result == null || !context.mounted) return;

    context.read<SavedReportsBloc>().add(
      SavedReportCreateRequested(
        name: result.name,
        definition: definition,
        visibility: result.visibility,
      ),
    );
  }
}

class _SaveReportRequest {
  const _SaveReportRequest({required this.name, required this.visibility});
  final String name;
  final SavedReportVisibility visibility;
}

class _SaveReportDialog extends StatefulWidget {
  const _SaveReportDialog({
    required this.permissionService,
    required this.organizationId,
    required this.userId,
  });

  final PermissionService permissionService;
  final String organizationId;
  final String userId;

  @override
  State<_SaveReportDialog> createState() => _SaveReportDialogState();
}

class _SaveReportDialogState extends State<_SaveReportDialog> {
  final _controller = TextEditingController();
  SavedReportVisibility _visibility = SavedReportVisibility.private;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Salvar visualização'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const Key('save-report-name'),
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome da visualização'),
        ),
        const SizedBox(height: 16),
        RadioListTile<SavedReportVisibility>(
          value: SavedReportVisibility.private,
          groupValue: _visibility,
          title: const Text('Privado'),
          onChanged: (value) => setState(() => _visibility = value!),
        ),
        PermissionBuilder(
          permissionService: widget.permissionService,
          organizationId: widget.organizationId,
          userId: widget.userId,
          capability: Capability.reportShareTeam,
          builder: (context, granted) => RadioListTile<SavedReportVisibility>(
            value: SavedReportVisibility.team,
            groupValue: _visibility,
            title: const Text('Minha equipe'),
            onChanged: granted
                ? (value) => setState(() => _visibility = value!)
                : null,
          ),
        ),
        PermissionBuilder(
          permissionService: widget.permissionService,
          organizationId: widget.organizationId,
          userId: widget.userId,
          capability: Capability.reportShareOrganization,
          builder: (context, granted) => RadioListTile<SavedReportVisibility>(
            value: SavedReportVisibility.organization,
            groupValue: _visibility,
            title: const Text('Toda a organização'),
            onChanged: granted
                ? (value) => setState(() => _visibility = value!)
                : null,
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          final name = _controller.text.trim();
          if (name.isEmpty) return;
          Navigator.of(
            context,
          ).pop(_SaveReportRequest(name: name, visibility: _visibility));
        },
        child: const Text('Salvar'),
      ),
    ],
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
