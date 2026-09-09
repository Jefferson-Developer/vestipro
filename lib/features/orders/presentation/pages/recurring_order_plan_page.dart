import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/recurring_order_plan.dart';
import '../../domain/value_objects/recurring_order_plan_status.dart';

typedef RecurringPlanSaveCallback =
    Future<void> Function(
      RecurringOrderFrequency frequency,
      DateTime nextExecutionAt,
      List<OrderItem> items,
    );

class RecurringOrderPlanPage extends StatefulWidget {
  const RecurringOrderPlanPage({
    required this.plan,
    required this.onSave,
    required this.onPause,
    required this.onCancel,
    super.key,
  });

  final RecurringOrderPlan plan;
  final RecurringPlanSaveCallback onSave;
  final Future<void> Function() onPause;
  final Future<void> Function() onCancel;

  @override
  State<RecurringOrderPlanPage> createState() => _RecurringOrderPlanPageState();
}

class _RecurringOrderPlanPageState extends State<RecurringOrderPlanPage> {
  late int _interval;
  late RecurringOrderFrequencyUnit _unit;
  late DateTime _nextExecutionAt;
  late List<OrderItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _interval = widget.plan.frequency.interval;
    _unit = widget.plan.frequency.unit;
    _nextExecutionAt = widget.plan.nextExecutionAt;
    _items = List<OrderItem>.of(widget.plan.items);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: AppAdminPageLayout(
        title: 'Pedido recorrente',
        actions: <Widget>[
          AppButton(
            label: 'Pausar',
            leadingIcon: Icons.pause_circle_outline,
            variant: AppButtonVariant.secondary,
            isDisabled:
                _isSaving ||
                widget.plan.status != RecurringOrderPlanStatus.active,
            onPressed: widget.plan.status == RecurringOrderPlanStatus.active
                ? () => _run(widget.onPause)
                : null,
          ),
          AppButton(
            label: 'Cancelar',
            leadingIcon: Icons.cancel_outlined,
            variant: AppButtonVariant.secondary,
            isDisabled:
                _isSaving ||
                widget.plan.status == RecurringOrderPlanStatus.canceled,
            onPressed: widget.plan.status != RecurringOrderPlanStatus.canceled
                ? () => _run(widget.onCancel)
                : null,
          ),
          AppButton(
            label: 'Salvar',
            leadingIcon: Icons.save_outlined,
            isLoading: _isSaving,
            isDisabled: _items.isEmpty || _interval <= 0,
            onPressed: _items.isEmpty || _interval <= 0
                ? null
                : () => _run(
                    () => widget.onSave(
                      RecurringOrderFrequency(interval: _interval, unit: _unit),
                      _nextExecutionAt,
                      _items,
                    ),
                  ),
          ),
        ],
        content: ListView(
          children: <Widget>[
            _PlanSummary(plan: widget.plan),
            const SizedBox(height: AppSpacing.spacing24),
            _ScheduleEditor(
              interval: _interval,
              unit: _unit,
              nextExecutionAt: _nextExecutionAt,
              onIntervalChanged: (value) => setState(() => _interval = value),
              onUnitChanged: (value) => setState(() => _unit = value),
              onDateChanged: (value) =>
                  setState(() => _nextExecutionAt = value),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Itens base',
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            for (final item in _items)
              _RecurringItemTile(
                item: item,
                onRemove: () => setState(() => _items.remove(item)),
              ),
            if (_items.isEmpty)
              const AppEmptyState(
                title: 'Nenhum item no plano',
                description: 'Adicione itens antes de salvar a recorrencia.',
              ),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              'Execucoes',
              style: AppTypography.titleMedium.copyWith(
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            if (widget.plan.executions.isEmpty)
              const AppEmptyState(
                title: 'Sem execucoes ainda',
                description: 'O historico aparece depois da primeira rodada.',
              )
            else
              for (final execution in widget.plan.executions)
                _ExecutionTile(execution: execution),
          ],
        ),
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan});

  final RecurringOrderPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.event_repeat_outlined, color: colors.primary),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Plano ${plan.status.label.toLowerCase()}',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  'Cliente ${plan.customerId} - proxima execucao em '
                  '${_formatDate(plan.nextExecutionAt)}.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEditor extends StatelessWidget {
  const _ScheduleEditor({
    required this.interval,
    required this.unit,
    required this.nextExecutionAt,
    required this.onIntervalChanged,
    required this.onUnitChanged,
    required this.onDateChanged,
  });

  final int interval;
  final RecurringOrderFrequencyUnit unit;
  final DateTime nextExecutionAt;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<RecurringOrderFrequencyUnit> onUnitChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.spacing16,
      runSpacing: AppSpacing.spacing16,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 160,
          child: TextFormField(
            key: const ValueKey<String>('recurring-interval-field'),
            initialValue: interval.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repetir a cada'),
            onChanged: (value) => onIntervalChanged(int.tryParse(value) ?? 0),
          ),
        ),
        DropdownButton<RecurringOrderFrequencyUnit>(
          key: const ValueKey<String>('recurring-unit-field'),
          value: unit,
          items: RecurringOrderFrequencyUnit.values
              .map(
                (value) => DropdownMenuItem<RecurringOrderFrequencyUnit>(
                  value: value,
                  child: Text(value.label),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onUnitChanged(value);
          },
        ),
        AppButton(
          label: _formatDate(nextExecutionAt),
          leadingIcon: Icons.calendar_today_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              initialDate: nextExecutionAt,
            );
            if (picked != null) onDateChanged(picked);
          },
        ),
      ],
    );
  }
}

class _RecurringItemTile extends StatelessWidget {
  const _RecurringItemTile({required this.item, required this.onRemove});

  final OrderItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Produto ${item.productId}'),
      subtitle: Text('${item.quantity} un. - variante ${item.variantId}'),
      trailing: IconButton(
        tooltip: 'Remover item',
        icon: const Icon(Icons.delete_outline),
        onPressed: onRemove,
      ),
    );
  }
}

class _ExecutionTile extends StatelessWidget {
  const _ExecutionTile({required this.execution});

  final RecurringOrderExecution execution;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history_outlined),
      title: Text(execution.orderNumber ?? execution.status),
      subtitle: Text(_formatDate(execution.processedAt)),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
