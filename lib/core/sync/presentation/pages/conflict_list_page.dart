import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../design_system/design_system.dart';
import '../../domain/entities/conflict_record.dart';
import '../cubit/conflict_list_cubit.dart';
import '../cubit/conflict_list_state.dart';
import '../widgets/conflict_record_card.dart';

/// Lists every open conflict of synchronization for [organizationId]
/// (TASK-111, EPIC-14 — seção 5.5 de `tasks.md`), prioritized with
/// financial/critical conflicts (pedidos) first — see
/// `ConflictListCubit.load`. Tapping a card calls [onConflictSelected], which
/// the host wires to `ConflictDetailRoute`.
class ConflictListPage extends StatelessWidget {
  const ConflictListPage({
    required this.organizationId,
    required this.createCubit,
    required this.onConflictSelected,
    super.key,
  });

  final String organizationId;
  final ConflictListCubit Function() createCubit;
  final ValueChanged<ConflictRecord> onConflictSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConflictListCubit>(
      create: (_) {
        final cubit = createCubit();
        unawaited(cubit.load(organizationId: organizationId));
        return cubit;
      },
      child: ConflictListView(onConflictSelected: onConflictSelected),
    );
  }
}

@visibleForTesting
class ConflictListView extends StatelessWidget {
  const ConflictListView({required this.onConflictSelected, super.key});

  final ValueChanged<ConflictRecord> onConflictSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Conflitos de sincronização'),
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      body: BlocBuilder<ConflictListCubit, ConflictListState>(
        builder: (context, state) {
          if (state.isInitialLoading) {
            return _buildLoading();
          }

          if (state.loadStatus == ConflictListLoadStatus.failure) {
            return AppErrorState(
              title: 'Não foi possível carregar os conflitos',
              message:
                  state.failure?.message ??
                  'Ocorreu um erro inesperado ao carregar a lista.',
              retryLabel: 'Tentar novamente',
              onRetry: () => context.read<ConflictListCubit>().load(
                organizationId: state.organizationId,
              ),
            );
          }

          if (state.isEmpty) {
            return const AppEmptyState(
              icon: Icons.check_circle_outline,
              title: 'Nenhum conflito pendente',
              description:
                  'Todas as alterações feitas offline foram sincronizadas '
                  'sem divergências que exigem sua decisão.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            itemCount: state.conflicts.length,
            itemBuilder: (context, index) {
              final record = state.conflicts[index];
              return ConflictRecordCard(
                record: record,
                onTap: () => onConflictSelected(record),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      children: List<Widget>.generate(
        4,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.spacing12),
          child: AppSkeleton.card(),
        ),
      ),
    );
  }
}
