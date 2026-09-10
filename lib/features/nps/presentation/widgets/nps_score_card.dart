import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/nps_aggregate_snapshot.dart';
import '../../domain/value_objects/nps_aggregate_scope.dart';
import '../cubit/nps_score_card_cubit.dart';
import '../cubit/nps_score_card_state.dart';

/// The "NPS" indicator card (TASK-202, EPIC-30) reused by every dashboard
/// that needs to show the pre-computed NPS agregado of one vendedor/equipe/
/// organização — never recomputed here (`tasks.md`: "nunca recalculado ad
/// hoc no cliente"), always read straight from
/// `NpsScoreCardCubit`/`npsMonthlyAggregates`.
class NpsScoreCard extends StatelessWidget {
  const NpsScoreCard({
    super.key,
    required this.organizationId,
    required this.companyId,
    required this.scope,
    required this.scopeId,
  });

  final String organizationId;
  final String companyId;
  final NpsAggregateScope scope;
  final String scopeId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NpsScoreCardCubit, NpsScoreCardState>(
      builder: (context, state) {
        return switch (state.status) {
          NpsScoreCardStatus.loading => const AppSkeleton.line(width: 160),
          NpsScoreCardStatus.error => AppKpiCard(
            label: 'NPS',
            value: 'Indisponível',
            icon: Icons.sentiment_neutral,
          ),
          NpsScoreCardStatus.ready => _ReadyCard(
            current: state.trend?.current,
            previous: state.trend?.previous,
          ),
        };
      },
    );
  }
}

class _ReadyCard extends StatelessWidget {
  const _ReadyCard({required this.current, required this.previous});

  final NpsAggregateSnapshot? current;
  final NpsAggregateSnapshot? previous;

  @override
  Widget build(BuildContext context) {
    final currentScore = current?.npsScore;
    if (currentScore == null) {
      return const AppKpiCard(
        label: 'NPS',
        value: 'Sem dados suficientes',
        icon: Icons.sentiment_neutral,
      );
    }

    final previousScore = previous?.npsScore;
    final delta = previousScore == null ? null : currentScore - previousScore;

    return AppKpiCard(
      label: 'NPS',
      value: currentScore.toStringAsFixed(1),
      icon: Icons.sentiment_satisfied_alt,
      trend: delta == null
          ? AppKpiTrend.neutral
          : delta > 0
          ? AppKpiTrend.up
          : delta < 0
          ? AppKpiTrend.down
          : AppKpiTrend.neutral,
      trendPercentage: delta,
      trendLabel: delta == null ? null : 'vs. mês anterior',
    );
  }
}
