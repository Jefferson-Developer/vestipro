import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/logistics_issue.dart';
import '../../domain/entities/shipment.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/value_objects/logistics_issue_type.dart';
import '../../domain/value_objects/shipment_status.dart';
import '../cubit/order_fulfillment_cubit.dart';
import '../cubit/order_fulfillment_state.dart';

/// Rastreio logístico do pedido (TASK-214, EPIC-32) — embutido no detalhe do
/// pedido (`OrderHistoryPage`), sempre visível (mesmo quando ainda não há
/// nenhuma expedição registrada). Ocorrências abertas ganham um destaque
/// visual e, para quem detém [Capability.shipmentManage], uma ação para
/// registrar uma nova ocorrência ou marcar uma existente como resolvida.
class OrderFulfillmentPanel extends StatelessWidget {
  const OrderFulfillmentPanel({
    required this.organizationId,
    required this.companyId,
    required this.orderId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String orderId;
  final String userId;
  final PermissionService permissionService;
  final OrderFulfillmentCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderFulfillmentCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(
          cubit.watch(organizationId: organizationId, orderId: orderId),
        );
        return cubit;
      },
      child: PermissionBuilder(
        permissionService: permissionService,
        organizationId: organizationId,
        userId: userId,
        capability: Capability.shipmentManage,
        builder: (context, canManage) => _FulfillmentBody(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
          canManage: canManage,
        ),
      ),
    );
  }
}

class _FulfillmentBody extends StatelessWidget {
  const _FulfillmentBody({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.canManage,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderFulfillmentCubit, OrderFulfillmentState>(
      listenWhen: (previous, current) =>
          previous.lastRegisteredIssueId != current.lastRegisteredIssueId ||
          previous.lastResolvedIssueId != current.lastResolvedIssueId ||
          previous.issueFailureMessage != current.issueFailureMessage,
      listener: (context, state) {
        if (state.issueFailureMessage != null) {
          AppSnackbar.show(
            context,
            message: state.issueFailureMessage!,
            variant: AppSnackbarVariant.error,
          );
        } else if (state.lastRegisteredIssueId != null) {
          AppSnackbar.show(context, message: 'Ocorrência registrada.');
        } else if (state.lastResolvedIssueId != null) {
          AppSnackbar.show(
            context,
            message: 'Ocorrência marcada como resolvida.',
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (state.status == OrderFulfillmentStatus.failure) {
          return Text(
            state.failureMessage ??
                'Não foi possível carregar o rastreio deste pedido.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.error,
            ),
          );
        }

        final shipment = state.selectedShipment;
        if (shipment == null) {
          return Text(
            'Nenhuma expedição registrada para este pedido ainda.',
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.outline,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ShipmentSummaryCard(shipment: shipment),
            if (state.hasEarlierShipments) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                '${state.shipments.length - 1} expedição(ões) anterior(es) '
                'também existem para este pedido.',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colors.outline,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              'Ocorrências',
              style: AppTypography.labelLarge.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            if (state.logisticsIssues.isEmpty)
              Text(
                'Nenhuma ocorrência registrada.',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colors.outline,
                ),
              )
            else
              for (final issue in state.logisticsIssues)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
                  child: _LogisticsIssueTile(
                    issue: issue,
                    canManage: canManage,
                    isSubmitting: state.isSubmittingIssue,
                  ),
                ),
            if (canManage) ...<Widget>[
              const SizedBox(height: AppSpacing.spacing8),
              AppButton(
                label: 'Reportar ocorrência',
                leadingIcon: Icons.report_problem_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () => _openReportIssueSheet(
                  context,
                  companyId: companyId,
                  defaultResponsibleUserId: shipment.sellerId,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              'Histórico de tracking',
              style: AppTypography.labelLarge.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            if (state.trackingEvents.isEmpty)
              Text(
                'Nenhum evento de tracking registrado ainda.',
                style: AppTypography.bodySmall.copyWith(
                  color: context.colors.outline,
                ),
              )
            else
              for (final event in state.trackingEvents.reversed)
                _TrackingEventTile(event: event),
          ],
        );
      },
    );
  }

  Future<void> _openReportIssueSheet(
    BuildContext context, {
    required String companyId,
    required String defaultResponsibleUserId,
  }) {
    final cubit = context.read<OrderFulfillmentCubit>();
    return AppBottomSheet.show<void>(
      context: context,
      title: 'Reportar ocorrência',
      contentKey: const Key('logistics-issue-report-sheet'),
      builder: (sheetContext) => BlocProvider<OrderFulfillmentCubit>.value(
        value: cubit,
        child: _ReportIssueForm(
          companyId: companyId,
          defaultResponsibleUserId: defaultResponsibleUserId,
        ),
      ),
    );
  }
}

class _ShipmentSummaryCard extends StatelessWidget {
  const _ShipmentSummaryCard({required this.shipment});

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  shipment.carrierName ?? 'Transportadora não informada',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppStatusBadge(
                label: shipment.status.label,
                variant: _variantFor(shipment.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            '${shipment.packages.length} volume(s) · '
            '${shipment.totalDeliveredQuantity}/${shipment.totalQuantity} itens entregues'
            '${shipment.carrierTrackingCode != null ? ' · código ${shipment.carrierTrackingCode}' : ''}',
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
          if (shipment.estimatedDeliveryDate != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing4),
              child: Text(
                'Previsão de entrega: ${_dateLabel(shipment.estimatedDeliveryDate!)}',
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
            ),
          if (shipment.hasOpenIssue)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.warning_amber_outlined,
                    color: colors.error,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.spacing8),
                  Expanded(
                    child: Text(
                      'Esta expedição tem ao menos uma ocorrência em aberto.',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  AppStatusBadgeVariant _variantFor(ShipmentStatus status) {
    return switch (status) {
      ShipmentStatus.delivered => AppStatusBadgeVariant.success,
      ShipmentStatus.partiallyDelivered => AppStatusBadgeVariant.warning,
      ShipmentStatus.returned ||
      ShipmentStatus.cancelled => AppStatusBadgeVariant.error,
      ShipmentStatus.pending => AppStatusBadgeVariant.neutral,
      _ => AppStatusBadgeVariant.info,
    };
  }
}

class _LogisticsIssueTile extends StatelessWidget {
  const _LogisticsIssueTile({
    required this.issue,
    required this.canManage,
    required this.isSubmitting,
  });

  final LogisticsIssue issue;
  final bool canManage;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  issue.type.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  issue.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  'Próxima ação: ${issue.nextAction}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              AppStatusBadge(
                label: issue.status.label,
                variant: issue.isOpen
                    ? AppStatusBadgeVariant.warning
                    : AppStatusBadgeVariant.success,
              ),
              if (canManage && issue.isOpen)
                AppButton(
                  label: 'Marcar como resolvida',
                  variant: AppButtonVariant.text,
                  isLoading: isSubmitting,
                  onPressed: isSubmitting
                      ? null
                      : () =>
                            context.read<OrderFulfillmentCubit>().resolveIssue(
                              logisticsIssueId: issue.id,
                              type: issue.type,
                            ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingEventTile extends StatelessWidget {
  const _TrackingEventTile({required this.event});

  final TrackingEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.circle, size: 8, color: colors.primary),
          const SizedBox(width: AppSpacing.spacing8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${event.type.label} · ${_dateLabel(event.occurredAt)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                if (event.description != null)
                  Text(
                    event.description!,
                    style: AppTypography.bodySmall.copyWith(
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

class _ReportIssueForm extends StatefulWidget {
  const _ReportIssueForm({
    required this.companyId,
    required this.defaultResponsibleUserId,
  });

  final String companyId;
  final String defaultResponsibleUserId;

  @override
  State<_ReportIssueForm> createState() => _ReportIssueFormState();
}

class _ReportIssueFormState extends State<_ReportIssueForm> {
  LogisticsIssueType _type = LogisticsIssueType.delay;
  late final TextEditingController _descriptionController;
  late final TextEditingController _nextActionController;
  late final TextEditingController _responsibleController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _nextActionController = TextEditingController();
    _responsibleController = TextEditingController(
      text: widget.defaultResponsibleUserId,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _nextActionController.dispose();
    _responsibleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderFulfillmentCubit, OrderFulfillmentState>(
      listener: (context, state) {
        if (state.lastRegisteredIssueId != null && !state.isSubmittingIssue) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DropdownButtonFormField<LogisticsIssueType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de ocorrência',
              ),
              items: LogisticsIssueType.values
                  .map(
                    (type) => DropdownMenuItem<LogisticsIssueType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _descriptionController,
              label: 'Descrição',
              isRequired: true,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _responsibleController,
              label: 'Responsável (id do usuário)',
              isRequired: true,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            AppTextField(
              controller: _nextActionController,
              label: 'Próxima ação',
              isRequired: true,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppButton(
              label: 'Registrar ocorrência',
              isLoading: state.isSubmittingIssue,
              onPressed: state.isSubmittingIssue
                  ? null
                  : () => _submit(context),
            ),
          ],
        );
      },
    );
  }

  void _submit(BuildContext context) {
    if (_descriptionController.text.trim().isEmpty ||
        _nextActionController.text.trim().isEmpty ||
        _responsibleController.text.trim().isEmpty) {
      return;
    }
    unawaited(
      context.read<OrderFulfillmentCubit>().reportIssue(
        companyId: widget.companyId,
        type: _type,
        description: _descriptionController.text.trim(),
        responsibleUserId: _responsibleController.text.trim(),
        nextAction: _nextActionController.text.trim(),
      ),
    );
  }
}

String _dateLabel(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
