import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../organizations/domain/entities/membership.dart';
import '../../domain/entities/report_export_result.dart';
import '../../domain/entities/report_schedule.dart';
import '../../domain/entities/saved_report.dart';
import '../bloc/report_schedules_bloc.dart';
import '../bloc/report_schedules_event.dart';
import '../bloc/report_schedules_state.dart';

/// "Agendamentos de relatório" (TASK-149) — the "tela mínima de gestão de
/// agendamentos" the task requires: criar, pausar e excluir a entrega
/// periódica de uma `SavedReport` já salva (TASK-145).
///
/// [schedulableReports] and [organizationMembers] are supplied by the caller
/// (already loaded elsewhere — "Meus relatórios", TASK-145; membros da
/// organização) instead of being fetched by this page itself, same
/// "pre-loaded lists passed in" convention already used by
/// `SavedReportsPage.onOpenReportBuilder`.
class ReportSchedulesPage extends StatelessWidget {
  const ReportSchedulesPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.schedulableReports,
    required this.organizationMembers,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final List<SavedReport> schedulableReports;
  final List<Membership> organizationMembers;
  final ReportSchedulesBloc Function() createBloc;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc()
      ..add(
        ReportSchedulesStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      ),
    child: _ReportSchedulesView(
      schedulableReports: schedulableReports,
      organizationMembers: organizationMembers,
    ),
  );
}

class _ReportSchedulesView extends StatelessWidget {
  const _ReportSchedulesView({
    required this.schedulableReports,
    required this.organizationMembers,
  });

  final List<SavedReport> schedulableReports;
  final List<Membership> organizationMembers;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Agendamentos de relatório')),
    floatingActionButton: schedulableReports.isEmpty
        ? null
        : FloatingActionButton.extended(
            onPressed: () => _openCreateDialog(context),
            icon: const Icon(Icons.add_alarm),
            label: const Text('Agendar relatório'),
          ),
    body: BlocConsumer<ReportSchedulesBloc, ReportSchedulesState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
          context.read<ReportSchedulesBloc>().add(
            const ReportSchedulesMessageCleared(),
          );
        } else if (state.successMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          context.read<ReportSchedulesBloc>().add(
            const ReportSchedulesMessageCleared(),
          );
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case ReportSchedulesStatus.initial:
          case ReportSchedulesStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case ReportSchedulesStatus.failure:
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.failure?.message ?? 'Não foi possível carregar.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<ReportSchedulesBloc>().add(
                      const ReportSchedulesRetried(),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          case ReportSchedulesStatus.ready:
            if (state.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text('Nenhum agendamento configurado ainda.'),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: state.schedules
                  .map(
                    (schedule) => _ScheduleTile(
                      key: ValueKey(schedule.id),
                      schedule: schedule,
                    ),
                  )
                  .toList(growable: false),
            );
        }
      },
    ),
  );

  Future<void> _openCreateDialog(BuildContext context) async {
    final bloc = context.read<ReportSchedulesBloc>();
    final request = await showDialog<_ScheduleCreationRequest>(
      context: context,
      builder: (dialogContext) => _CreateScheduleDialog(
        schedulableReports: schedulableReports,
        organizationMembers: organizationMembers,
      ),
    );
    if (request == null) return;
    bloc.add(
      ReportScheduleCreateRequested(
        savedReport: request.savedReport,
        frequency: request.frequency,
        weekday: request.weekday,
        dayOfMonth: request.dayOfMonth,
        hour: request.hour,
        minute: request.minute,
        format: request.format,
        recipientUserIds: request.recipientUserIds,
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required super.key, required this.schedule});

  final ReportSchedule schedule;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        schedule.isActive
            ? Icons.play_circle_outline
            : Icons.pause_circle_outline,
        color: schedule.isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(schedule.savedReportName),
      subtitle: Text(
        '${_frequencyLabel(schedule)} · ${_formatLabel(schedule.format)} · '
        '${schedule.recipientUserIds.length} destinatário(s)'
        '${_lastRunSuffix(schedule)}',
      ),
      trailing: PopupMenuButton<_ScheduleAction>(
        onSelected: (action) => _onSelected(context, action),
        itemBuilder: (context) => [
          if (schedule.isActive)
            const PopupMenuItem(
              value: _ScheduleAction.pause,
              child: Text('Pausar'),
            ),
          const PopupMenuItem(
            value: _ScheduleAction.delete,
            child: Text('Excluir'),
          ),
        ],
      ),
    ),
  );

  void _onSelected(BuildContext context, _ScheduleAction action) {
    final bloc = context.read<ReportSchedulesBloc>();
    switch (action) {
      case _ScheduleAction.pause:
        bloc.add(ReportSchedulePauseRequested(schedule));
      case _ScheduleAction.delete:
        bloc.add(ReportScheduleDeleteRequested(schedule));
    }
  }

  String _lastRunSuffix(ReportSchedule schedule) {
    if (schedule.lastRunStatus == null) return '';
    return switch (schedule.lastRunStatus!) {
      ReportScheduleRunStatus.success => ' · última entrega: sucesso',
      ReportScheduleRunStatus.partialFailure =>
        ' · última entrega: parcial (ver detalhes)',
      ReportScheduleRunStatus.failure => ' · última entrega: falhou',
    };
  }
}

enum _ScheduleAction { pause, delete }

String _frequencyLabel(ReportSchedule schedule) {
  final time =
      '${schedule.hour.toString().padLeft(2, '0')}:'
      '${schedule.minute.toString().padLeft(2, '0')}';
  return switch (schedule.frequency) {
    ReportScheduleFrequency.daily => 'Diariamente às $time',
    ReportScheduleFrequency.weekly =>
      'Semanalmente (${_weekdayLabel(schedule.weekday)}) às $time',
    ReportScheduleFrequency.monthly =>
      'Mensalmente (dia ${schedule.dayOfMonth}) às $time',
  };
}

String _weekdayLabel(int? weekday) => switch (weekday) {
  DateTime.monday => 'segunda-feira',
  DateTime.tuesday => 'terça-feira',
  DateTime.wednesday => 'quarta-feira',
  DateTime.thursday => 'quinta-feira',
  DateTime.friday => 'sexta-feira',
  DateTime.saturday => 'sábado',
  DateTime.sunday => 'domingo',
  _ => 'dia indefinido',
};

String _formatLabel(ReportExportFormat format) => switch (format) {
  ReportExportFormat.csv => 'CSV',
  ReportExportFormat.xlsx => 'XLSX',
  ReportExportFormat.pdf => 'PDF',
};

final class _ScheduleCreationRequest {
  const _ScheduleCreationRequest({
    required this.savedReport,
    required this.frequency,
    this.weekday,
    this.dayOfMonth,
    required this.hour,
    required this.minute,
    required this.format,
    required this.recipientUserIds,
  });

  final SavedReport savedReport;
  final ReportScheduleFrequency frequency;
  final int? weekday;
  final int? dayOfMonth;
  final int hour;
  final int minute;
  final ReportExportFormat format;
  final List<String> recipientUserIds;
}

class _CreateScheduleDialog extends StatefulWidget {
  const _CreateScheduleDialog({
    required this.schedulableReports,
    required this.organizationMembers,
  });

  final List<SavedReport> schedulableReports;
  final List<Membership> organizationMembers;

  @override
  State<_CreateScheduleDialog> createState() => _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends State<_CreateScheduleDialog> {
  late SavedReport _savedReport = widget.schedulableReports.first;
  ReportScheduleFrequency _frequency = ReportScheduleFrequency.daily;
  int _weekday = DateTime.monday;
  int _dayOfMonth = 1;
  int _hour = 8;
  int _minute = 0;
  ReportExportFormat _format = ReportExportFormat.pdf;
  final Set<String> _recipientUserIds = <String>{};

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Novo agendamento'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<SavedReport>(
              initialValue: _savedReport,
              decoration: const InputDecoration(
                labelText: 'Visualização salva',
              ),
              items: widget.schedulableReports
                  .map(
                    (report) => DropdownMenuItem(
                      value: report,
                      child: Text(report.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) =>
                  setState(() => _savedReport = value ?? _savedReport),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportScheduleFrequency>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequência'),
              items: const [
                DropdownMenuItem(
                  value: ReportScheduleFrequency.daily,
                  child: Text('Diariamente'),
                ),
                DropdownMenuItem(
                  value: ReportScheduleFrequency.weekly,
                  child: Text('Semanalmente'),
                ),
                DropdownMenuItem(
                  value: ReportScheduleFrequency.monthly,
                  child: Text('Mensalmente'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _frequency = value ?? _frequency),
            ),
            if (_frequency == ReportScheduleFrequency.weekly) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _weekday,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: [
                  for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                    DropdownMenuItem(
                      value: day,
                      child: Text(_weekdayLabel(day)),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _weekday = value ?? _weekday),
              ),
            ],
            if (_frequency == ReportScheduleFrequency.monthly) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dayOfMonth,
                decoration: const InputDecoration(labelText: 'Dia do mês'),
                items: [
                  for (var day = 1; day <= 28; day++)
                    DropdownMenuItem(value: day, child: Text('Dia $day')),
                ],
                onChanged: (value) =>
                    setState(() => _dayOfMonth = value ?? _dayOfMonth),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _hour,
                    decoration: const InputDecoration(labelText: 'Hora'),
                    items: [
                      for (var hour = 0; hour < 24; hour++)
                        DropdownMenuItem(
                          value: hour,
                          child: Text(hour.toString().padLeft(2, '0')),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _hour = value ?? _hour),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _minute,
                    decoration: const InputDecoration(labelText: 'Minuto'),
                    items: [
                      for (var minute = 0; minute < 60; minute += 15)
                        DropdownMenuItem(
                          value: minute,
                          child: Text(minute.toString().padLeft(2, '0')),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _minute = value ?? _minute),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReportExportFormat>(
              initialValue: _format,
              decoration: const InputDecoration(labelText: 'Formato'),
              items: const [
                DropdownMenuItem(
                  value: ReportExportFormat.pdf,
                  child: Text('PDF'),
                ),
                DropdownMenuItem(
                  value: ReportExportFormat.xlsx,
                  child: Text('XLSX'),
                ),
                DropdownMenuItem(
                  value: ReportExportFormat.csv,
                  child: Text('CSV'),
                ),
              ],
              onChanged: (value) => setState(() => _format = value ?? _format),
            ),
            const SizedBox(height: 12),
            Text(
              'Destinatários',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            ...widget.organizationMembers.map(
              (member) => CheckboxListTile(
                dense: true,
                value: _recipientUserIds.contains(member.userId),
                title: Text(member.name ?? member.email ?? member.userId),
                onChanged: (checked) => setState(() {
                  if (checked ?? false) {
                    _recipientUserIds.add(member.userId);
                  } else {
                    _recipientUserIds.remove(member.userId);
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _recipientUserIds.isEmpty
            ? null
            : () => Navigator.of(context).pop(
                _ScheduleCreationRequest(
                  savedReport: _savedReport,
                  frequency: _frequency,
                  weekday: _frequency == ReportScheduleFrequency.weekly
                      ? _weekday
                      : null,
                  dayOfMonth: _frequency == ReportScheduleFrequency.monthly
                      ? _dayOfMonth
                      : null,
                  hour: _hour,
                  minute: _minute,
                  format: _format,
                  recipientUserIds: _recipientUserIds.toList(growable: false),
                ),
              ),
        child: const Text('Agendar'),
      ),
    ],
  );
}
