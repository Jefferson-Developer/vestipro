import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/post_sale_event.dart';
import '../../domain/value_objects/post_sale_event_type.dart';
import '../cubit/post_sale_timeline_cubit.dart';
import '../cubit/post_sale_timeline_state.dart';

/// Timeline de pós-venda vinculada ao pedido (TASK-201, EPIC-30) — embutida
/// no detalhe do pedido (`OrderHistoryPage`), reaproveitando o mesmo
/// componente visual de timeline já usado pelo CRM (`AppTimeline`,
/// `CrmActivityTimeline`, TASK-059). Sempre visível (mesmo quando vazia) para
/// deixar claro que nenhum evento de pós-venda foi registrado ainda. Inclui
/// tanto os marcos manuais (despachado, em trânsito, entregue, problema
/// reportado, em resolução, resolvido) quanto os eventos de devolução/troca
/// auto-vinculados pelas Cloud Functions de TASK-199/TASK-200 (`tasks.md`:
/// "visão única de pós-venda do pedido").
class PostSaleTimelineSection extends StatelessWidget {
  const PostSaleTimelineSection({
    required this.organizationId,
    required this.orderId,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String orderId;
  final PostSaleTimelineCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostSaleTimelineCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(
          cubit.watch(organizationId: organizationId, orderId: orderId),
        );
        return cubit;
      },
      child: BlocBuilder<PostSaleTimelineCubit, PostSaleTimelineState>(
        builder: (context, state) {
          if (state.status == PostSaleTimelineStatus.initial ||
              state.status == PostSaleTimelineStatus.loading) {
            return const SizedBox.shrink();
          }
          if (state.status == PostSaleTimelineStatus.error) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Pós-venda',
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              if (state.events.isEmpty)
                Text(
                  'Nenhum evento de pós-venda registrado para este pedido.',
                  style: AppTypography.bodySmall.copyWith(
                    color: context.colors.outline,
                  ),
                )
              else
                AppTimeline(
                  entries: state.events
                      .map((event) => _entryFor(event))
                      .toList(growable: false),
                ),
            ],
          );
        },
      ),
    );
  }
}

AppTimelineEntry _entryFor(PostSaleEvent event) {
  return AppTimelineEntry(
    title: event.type.label,
    icon: _iconFor(event.type),
    timestampLabel: _dateTimeLabel(event.createdAt),
    description: event.description ?? 'Sem descrição adicional.',
    subtitle: event.createdByName == null
        ? null
        : 'Registrado por ${event.createdByName}',
    isHighlighted: event.isProblem,
    semanticLabel:
        '${event.type.label}, ${event.description ?? 'sem descrição'}, '
        '${_dateTimeLabel(event.createdAt)}',
  );
}

IconData _iconFor(PostSaleEventType type) {
  return switch (type) {
    PostSaleEventType.dispatched => Icons.outbound_outlined,
    PostSaleEventType.inTransit => Icons.local_shipping_outlined,
    PostSaleEventType.delivered => Icons.inventory_2_outlined,
    PostSaleEventType.problemReported => Icons.report_problem_outlined,
    PostSaleEventType.inResolution => Icons.build_outlined,
    PostSaleEventType.resolved => Icons.task_alt_outlined,
    PostSaleEventType.returnRequested ||
    PostSaleEventType.returnResolved => Icons.keyboard_return_outlined,
    PostSaleEventType.exchangeRequested ||
    PostSaleEventType.exchangeResolved => Icons.swap_horiz_outlined,
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
