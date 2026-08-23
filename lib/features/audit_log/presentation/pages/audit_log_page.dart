import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../bloc/audit_log_action_filter.dart';
import '../bloc/audit_log_bloc.dart';
import '../bloc/audit_log_event.dart';
import '../bloc/audit_log_state.dart';
import '../presenters/audit_log_presenter.dart';

class AuditLogPage extends StatelessWidget {
  const AuditLogPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final AuditLogBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.auditLogView,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<AuditLogBloc>(
          create: (_) => createBloc()
            ..add(
              AuditLogStarted(organizationId: organizationId, userId: userId),
            ),
          child: const _AuditLogView(),
        );
      },
    );
  }
}

class _AuditLogView extends StatelessWidget {
  const _AuditLogView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuditLogBloc, AuditLogState>(
        builder: (context, state) {
          final bloc = context.read<AuditLogBloc>();
          return AppAdminPageLayout(
            title: 'Auditoria de acessos',
            filtersBuilder: (context) => _AuditLogFilters(state: state),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppDataTable<AuditLogEntry>(
                          status: _tableStatus(state),
                          rows: state.entries,
                          rowIdBuilder: (entry) => entry.id,
                          emptyTitle: 'Nenhum evento de auditoria encontrado',
                          emptyDescription:
                              'Ajuste período, ator ou ação para consultar outros eventos.',
                          errorTitle: 'Não foi possível carregar a auditoria',
                          errorMessage:
                              state.loadFailure?.message ??
                              'Tente novamente em breve.',
                          retryLabel: 'Tentar novamente',
                          onRetry: () =>
                              bloc.add(const AuditLogRefreshRequested()),
                          mobileCardTitleBuilder: (context, entry) =>
                              Text(auditActionLabel(entry.action)),
                          columns: <AppDataColumn<AuditLogEntry>>[
                            AppDataColumn(
                              label: 'Data/hora',
                              cellBuilder: (context, entry) =>
                                  Text(_dateTimeLabel(entry.timestamp)),
                            ),
                            AppDataColumn(
                              label: 'Ator',
                              cellBuilder: (context, entry) => Text(
                                '${entry.actorName}\n${entry.actorUserId}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            AppDataColumn(
                              label: 'Ação',
                              cellBuilder: (context, entry) =>
                                  Text(auditActionLabel(entry.action)),
                            ),
                            AppDataColumn(
                              label: 'Entidade afetada',
                              cellBuilder: (context, entry) =>
                                  Text(auditEntityLabel(entry)),
                            ),
                            AppDataColumn(
                              label: 'Detalhes',
                              cellBuilder: (context, entry) => Text(
                                auditDetailsLabel(entry),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (state.loadStatus == AuditLogLoadStatus.ready) ...[
                          const SizedBox(height: AppSpacing.spacing8),
                          AppPagination(
                            hasMore: state.hasMore,
                            isLoadingMore: state.isLoadingNextPage,
                            onLoadMore: () =>
                                bloc.add(const AuditLogLoadMoreRequested()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  AppDataTableStatus _tableStatus(AuditLogState state) {
    return switch (state.loadStatus) {
      AuditLogLoadStatus.loading => AppDataTableStatus.loading,
      AuditLogLoadStatus.failure => AppDataTableStatus.error,
      AuditLogLoadStatus.ready =>
        state.entries.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }
}

class _AuditLogFilters extends StatefulWidget {
  const _AuditLogFilters({required this.state});

  final AuditLogState state;

  @override
  State<_AuditLogFilters> createState() => _AuditLogFiltersState();
}

class _AuditLogFiltersState extends State<_AuditLogFilters> {
  late final TextEditingController _actorController;
  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  String? _periodError;

  @override
  void initState() {
    super.initState();
    _actorController = TextEditingController(text: widget.state.actorUserId);
    _fromController = TextEditingController(
      text: _dateInputLabel(widget.state.from),
    );
    _toController = TextEditingController(
      text: _dateInputLabel(widget.state.to),
    );
  }

  @override
  void didUpdateWidget(covariant _AuditLogFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.actorUserId != widget.state.actorUserId) {
      _actorController.text = widget.state.actorUserId;
    }
    if (oldWidget.state.from != widget.state.from) {
      _fromController.text = _dateInputLabel(widget.state.from);
    }
    if (oldWidget.state.to != widget.state.to) {
      _toController.text = _dateInputLabel(widget.state.to);
    }
  }

  @override
  void dispose() {
    _actorController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bloc = context.read<AuditLogBloc>();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Período',
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppTextField(
            key: const ValueKey('audit_log_from_filter'),
            controller: _fromController,
            label: 'De',
            hintText: 'AAAA-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppTextField(
            key: const ValueKey('audit_log_to_filter'),
            controller: _toController,
            label: 'Até',
            hintText: 'AAAA-MM-DD',
            keyboardType: TextInputType.datetime,
          ),
          if (_periodError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              _periodError!,
              style: AppTypography.bodySmall.copyWith(color: colors.error),
            ),
          ],
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            key: const ValueKey('audit_log_actor_filter'),
            controller: _actorController,
            label: 'Ator',
            hintText: 'ID do usuário',
            prefixIcon: const Icon(Icons.person_search_outlined),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applyTextFilters(context),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Aplicar',
            leadingIcon: Icons.check_outlined,
            onPressed: () => _applyTextFilters(context),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          AppButton(
            label: 'Limpar',
            leadingIcon: Icons.clear_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled:
                !widget.state.hasActiveFilters &&
                _actorController.text.isEmpty &&
                _fromController.text.isEmpty &&
                _toController.text.isEmpty,
            onPressed: () {
              setState(() => _periodError = null);
              _actorController.clear();
              _fromController.clear();
              _toController.clear();
              bloc.add(const AuditLogFiltersCleared());
            },
          ),
          const SizedBox(height: AppSpacing.spacing24),
          Text(
            'Ação',
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              AppFilterChip(
                label: 'Todas',
                selected: widget.state.actionFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    bloc.add(const AuditLogActionFilterChanged(null));
                  }
                },
              ),
              for (final filter in AuditLogActionFilter.values)
                AppFilterChip(
                  label: filter.label,
                  selected: widget.state.actionFilter == filter,
                  onSelected: (selected) {
                    bloc.add(
                      AuditLogActionFilterChanged(selected ? filter : null),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyTextFilters(BuildContext context) {
    final from = _parseDate(_fromController.text);
    final to = _parseDate(_toController.text, endOfDay: true);

    if (from == _invalidDate || to == _invalidDate) {
      setState(() {
        _periodError = 'Use datas válidas no formato AAAA-MM-DD.';
      });
      return;
    }
    if (from != null && to != null && from.isAfter(to)) {
      setState(() {
        _periodError = 'A data inicial deve ser anterior à data final.';
      });
      return;
    }

    setState(() => _periodError = null);
    context.read<AuditLogBloc>().add(
      AuditLogTextFiltersApplied(
        actorUserId: _actorController.text,
        from: from,
        to: to,
      ),
    );
  }
}

final DateTime _invalidDate = DateTime.utc(1);

DateTime? _parseDate(String value, {bool endOfDay = false}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final parts = trimmed.split('-');
  if (parts.length != 3) return _invalidDate;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return _invalidDate;

  final parsed = endOfDay
      ? DateTime(year, month, day, 23, 59, 59, 999)
      : DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return _invalidDate;
  }
  return parsed;
}

String _dateInputLabel(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
