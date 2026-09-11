import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/pre_book_program.dart';

class PreBookProgramPage extends StatelessWidget {
  const PreBookProgramPage({
    required this.program,
    required this.metrics,
    required this.availability,
    required this.now,
    this.canCreatePreBookOrder = true,
    this.onCreatePreBookOrder,
    super.key,
  });

  final PreBookProgram program;
  final PreBookCaptureMetrics metrics;
  final List<PreBookVariantAvailability> availability;
  final DateTime now;
  final bool canCreatePreBookOrder;
  final VoidCallback? onCreatePreBookOrder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dateFormat = DateFormat.yMd(Intl.getCurrentLocale());
    final isOpen = program.isSalesWindowOpen(now);
    final statusVariant = switch (program.status) {
      PreBookProgramStatus.open when isOpen => AppStatusBadgeVariant.success,
      PreBookProgramStatus.open => AppStatusBadgeVariant.warning,
      PreBookProgramStatus.closed => AppStatusBadgeVariant.warning,
      PreBookProgramStatus.cancelled => AppStatusBadgeVariant.error,
      PreBookProgramStatus.draft => AppStatusBadgeVariant.neutral,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Pre-book da colecao')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.spacing12,
            runSpacing: AppSpacing.spacing12,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      program.name,
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      'Colecao ${program.collectionId} | vendas ${dateFormat.format(program.salesWindowStart)} a ${dateFormat.format(program.salesWindowEnd)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              AppStatusBadge(
                label: isOpen ? 'Janela aberta' : _programStatusLabel(program),
                variant: statusVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          _MetricsBand(metrics: metrics),
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            'Janelas de entrega',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          for (final window in program.deliveryWindows) ...<Widget>[
            _DeliveryWindowTile(window: window, dateFormat: dateFormat),
            const SizedBox(height: AppSpacing.spacing8),
          ],
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Disponibilidade futura',
            style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          if (availability.isEmpty)
            const AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Sem disponibilidade futura',
              description:
                  'Este programa ainda nao possui previsao, alocacao ou reserva firme para promessa de entrega.',
            )
          else
            for (final item in availability) ...<Widget>[
              _AvailabilityTile(item: item, dateFormat: dateFormat),
              const SizedBox(height: AppSpacing.spacing8),
            ],
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Criar pedido pre-book',
            leadingIcon: Icons.event_available_outlined,
            isDisabled: !isOpen || !canCreatePreBookOrder,
            onPressed: isOpen && canCreatePreBookOrder
                ? onCreatePreBookOrder
                : null,
          ),
        ],
      ),
    );
  }

  String _programStatusLabel(PreBookProgram program) {
    return switch (program.status) {
      PreBookProgramStatus.draft => 'Rascunho',
      PreBookProgramStatus.open => 'Fora da janela',
      PreBookProgramStatus.closed => 'Encerrado',
      PreBookProgramStatus.cancelled => 'Cancelado',
    };
  }
}

class _MetricsBand extends StatelessWidget {
  const _MetricsBand({required this.metrics});

  final PreBookCaptureMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final percent = NumberFormat.percentPattern(
      Intl.getCurrentLocale(),
    ).format(metrics.targetProgress);
    return Wrap(
      spacing: AppSpacing.spacing8,
      runSpacing: AppSpacing.spacing8,
      children: <Widget>[
        _MetricChip(
          label: 'Reservado',
          value: '${metrics.reservedPieces} pecas',
        ),
        _MetricChip(label: 'Vendido', value: '${metrics.soldPieces} pecas'),
        _MetricChip(
          label: 'Cancelado',
          value: '${metrics.cancelledPieces} pecas',
        ),
        _MetricChip(label: 'Meta', value: percent),
        _MetricChip(label: 'Gap', value: '${metrics.targetGap} pecas'),
        AppStatusBadge(
          label: _riskLabel(metrics.deliveryRisk),
          variant: _riskVariant(metrics.deliveryRisk),
        ),
      ],
    );
  }

  String _riskLabel(PreBookProductionRisk risk) => switch (risk) {
    PreBookProductionRisk.low => 'Entrega saudavel',
    PreBookProductionRisk.attention => 'Risco de entrega',
    PreBookProductionRisk.high => 'Risco alto',
  };

  AppStatusBadgeVariant _riskVariant(PreBookProductionRisk risk) =>
      switch (risk) {
        PreBookProductionRisk.low => AppStatusBadgeVariant.success,
        PreBookProductionRisk.attention => AppStatusBadgeVariant.warning,
        PreBookProductionRisk.high => AppStatusBadgeVariant.error,
      };
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.colors.outline),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: context.colors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryWindowTile extends StatelessWidget {
  const _DeliveryWindowTile({required this.window, required this.dateFormat});

  final PreBookDeliveryWindow window;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.local_shipping_outlined),
      title: Text(window.label),
      subtitle: Text(
        '${dateFormat.format(window.startsAt)} a ${dateFormat.format(window.endsAt)}',
      ),
    );
  }
}

class _AvailabilityTile extends StatelessWidget {
  const _AvailabilityTile({required this.item, required this.dateFormat});

  final PreBookVariantAvailability item;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final expectedDate = item.expectedDate;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text('Variante ${item.variantId}'),
      subtitle: Text(
        expectedDate == null
            ? 'Disponibilidade futura estimada'
            : 'Promessa ${dateFormat.format(expectedDate)}',
      ),
      trailing: AppStatusBadge(
        label:
            '${item.availableToPromise} futuras | ${_availabilityLabel(item.status)}',
        variant: _availabilityVariant(item.status),
      ),
    );
  }

  String _availabilityLabel(PreBookAvailabilityStatus status) =>
      switch (status) {
        PreBookAvailabilityStatus.forecast => 'previsao',
        PreBookAvailabilityStatus.allocated => 'alocado',
        PreBookAvailabilityStatus.firmReserved => 'reserva firme',
        PreBookAvailabilityStatus.unavailable => 'indisponivel',
      };

  AppStatusBadgeVariant _availabilityVariant(
    PreBookAvailabilityStatus status,
  ) => switch (status) {
    PreBookAvailabilityStatus.forecast => AppStatusBadgeVariant.info,
    PreBookAvailabilityStatus.allocated => AppStatusBadgeVariant.success,
    PreBookAvailabilityStatus.firmReserved => AppStatusBadgeVariant.success,
    PreBookAvailabilityStatus.unavailable => AppStatusBadgeVariant.error,
  };
}
