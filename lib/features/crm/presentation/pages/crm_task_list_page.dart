import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/value_objects/crm_task_priority.dart';
import '../bloc/crm_task_list_bloc.dart';
import '../bloc/crm_task_list_event.dart';
import '../bloc/crm_task_list_state.dart';

class CrmTaskListPage extends StatelessWidget {
  const CrmTaskListPage({
    required this.organizationId,
    required this.userId,
    required this.createBloc,
    this.visibleResponsibleUserIds,
    this.canManageOthers = false,
    this.now,
    super.key,
  });

  final String organizationId;
  final String userId;
  final CrmTaskListBloc Function() createBloc;
  final Set<String>? visibleResponsibleUserIds;
  final bool canManageOthers;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final visibleIds = visibleResponsibleUserIds ?? <String>{userId};
    return BlocProvider<CrmTaskListBloc>(
      create: (_) => createBloc()
        ..add(
          CrmTaskListStarted(
            organizationId: organizationId,
            userId: userId,
            visibleResponsibleUserIds: visibleIds,
            canManageOthers: canManageOthers,
          ),
        ),
      child: _CrmTaskListScaffold(now: now ?? DateTime.now),
    );
  }
}

class _CrmTaskListScaffold extends StatelessWidget {
  const _CrmTaskListScaffold({required this.now});

  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Tarefas e follow-ups',
        content: _CrmTaskListContent(now: now),
      ),
    );
  }
}

class _CrmTaskListContent extends StatelessWidget {
  const _CrmTaskListContent({required this.now});

  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CrmTaskListBloc, CrmTaskListState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != CrmTaskListActionStatus.submitting,
      listener: (context, state) {
        switch (state.actionStatus) {
          case CrmTaskListActionStatus.success:
            AppSnackbar.show(
              context,
              message: 'Tarefa concluida.',
              variant: AppSnackbarVariant.success,
            );
            context.read<CrmTaskListBloc>().add(
              const CrmTaskListActionDismissed(),
            );
          case CrmTaskListActionStatus.failure:
            AppSnackbar.show(
              context,
              message:
                  state.actionFailure?.message ??
                  'Nao foi possivel concluir a tarefa.',
              variant: AppSnackbarVariant.error,
            );
            context.read<CrmTaskListBloc>().add(
              const CrmTaskListActionDismissed(),
            );
          case CrmTaskListActionStatus.idle:
          case CrmTaskListActionStatus.submitting:
            break;
        }
      },
      builder: (context, state) {
        if (state.status == CrmTaskListLoadStatus.failure) {
          return AppErrorState(
            title: 'Nao foi possivel carregar as tarefas',
            message: state.failure?.message ?? 'Tente novamente em breve.',
            retryLabel: 'Tentar novamente',
            onRetry: () =>
                context.read<CrmTaskListBloc>().add(const CrmTaskListRetried()),
          );
        }
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.tasks.isEmpty) {
          return const AppEmptyState(
            title: 'Nenhuma pendencia no periodo',
            description: 'Follow-ups e tarefas da semana aparecem aqui.',
            icon: Icons.task_alt,
          );
        }

        final groups = groupCrmTasksForWeek(state.tasks, now().toUtc());
        return ListView(
          children: <Widget>[
            _TaskGroupSection(
              title: 'Atrasadas',
              icon: Icons.warning_amber_outlined,
              tasks: groups.overdue,
              state: state,
              now: now().toUtc(),
            ),
            _TaskGroupSection(
              title: 'Hoje',
              icon: Icons.today_outlined,
              tasks: groups.today,
              state: state,
              now: now().toUtc(),
            ),
            _TaskGroupSection(
              title: 'Esta semana',
              icon: Icons.date_range_outlined,
              tasks: groups.week,
              state: state,
              now: now().toUtc(),
            ),
          ],
        );
      },
    );
  }
}

final class CrmTaskGroups {
  const CrmTaskGroups({
    required this.overdue,
    required this.today,
    required this.week,
  });

  final List<CrmTask> overdue;
  final List<CrmTask> today;
  final List<CrmTask> week;
}

@visibleForTesting
CrmTaskGroups groupCrmTasksForWeek(List<CrmTask> tasks, DateTime now) {
  final todayStart = DateTime.utc(now.year, now.month, now.day);
  final tomorrowStart = DateTime.utc(now.year, now.month, now.day + 1);
  final weekLimit = DateTime.utc(now.year, now.month, now.day + 7);
  final overdue = <CrmTask>[];
  final today = <CrmTask>[];
  final week = <CrmTask>[];

  for (final task in tasks) {
    if (task.isOverdue(now)) {
      overdue.add(task);
    } else if (!task.dueAt.isBefore(todayStart) &&
        task.dueAt.isBefore(tomorrowStart)) {
      today.add(task);
    } else if (!task.dueAt.isBefore(tomorrowStart) &&
        task.dueAt.isBefore(weekLimit)) {
      week.add(task);
    }
  }

  return CrmTaskGroups(overdue: overdue, today: today, week: week);
}

class _TaskGroupSection extends StatelessWidget {
  const _TaskGroupSection({
    required this.title,
    required this.icon,
    required this.tasks,
    required this.state,
    required this.now,
  });

  final String title;
  final IconData icon;
  final List<CrmTask> tasks;
  final CrmTaskListState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.spacing8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              Text(
                '${tasks.length}',
                style: AppTypography.labelLarge.copyWith(color: colors.outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          if (tasks.isEmpty)
            _InlineTaskEmpty(text: 'Nenhuma tarefa em "$title".')
          else
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                child: _TaskTile(
                  task: task,
                  isProcessing: state.isProcessing(task.id),
                  now: now,
                  canComplete:
                      state.canManageOthers ||
                      task.responsibleUserId == state.userId,
                ),
              ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.isProcessing,
    required this.now,
    required this.canComplete,
  });

  final CrmTask task;
  final bool isProcessing;
  final DateTime now;
  final bool canComplete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isOverdue = task.isOverdue(now);
    return Container(
      key: Key('crm-task-${task.id}'),
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: isOverdue
            ? Color.alphaBlend(
                colors.warning.withValues(alpha: 0.09),
                colors.surface,
              )
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(
          color: isOverdue
              ? colors.warning.withValues(alpha: 0.44)
              : colors.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            isOverdue ? Icons.warning_amber_outlined : Icons.task_alt,
            color: isOverdue ? colors.warning : colors.primary,
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.title,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (task.description?.trim().isNotEmpty ?? false) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    task.description!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.spacing8),
                Wrap(
                  spacing: AppSpacing.spacing8,
                  runSpacing: AppSpacing.spacing8,
                  children: <Widget>[
                    AppStatusBadge(
                      label: 'Vence ${_dateTimeLabel(task.dueAt)}',
                      variant: AppStatusBadgeVariant.neutral,
                      icon: Icons.schedule,
                    ),
                    AppStatusBadge(
                      label: task.priority.label,
                      variant: _priorityVariant(task.priority),
                      icon: Icons.flag_outlined,
                    ),
                    if (isOverdue)
                      const AppStatusBadge(
                        label: 'Atrasada',
                        variant: AppStatusBadgeVariant.warning,
                        icon: Icons.warning_amber_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          AppButton(
            label: 'Concluir',
            leadingIcon: Icons.check,
            variant: AppButtonVariant.secondary,
            isLoading: isProcessing,
            isDisabled: !canComplete,
            onPressed: canComplete
                ? () => context.read<CrmTaskListBloc>().add(
                    CrmTaskListTaskCompleted(task.id),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _InlineTaskEmpty extends StatelessWidget {
  const _InlineTaskEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(color: colors.outline),
      ),
    );
  }
}

AppStatusBadgeVariant _priorityVariant(CrmTaskPriority priority) {
  return switch (priority) {
    CrmTaskPriority.low => AppStatusBadgeVariant.neutral,
    CrmTaskPriority.medium => AppStatusBadgeVariant.info,
    CrmTaskPriority.high => AppStatusBadgeVariant.warning,
  };
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
