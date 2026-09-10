import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/value_objects/nps_survey_outcome.dart';
import '../bloc/nps_response_bloc.dart';
import '../bloc/nps_response_event.dart';
import '../bloc/nps_response_state.dart';

/// The public, unauthenticated NPS survey response screen (TASK-202,
/// EPIC-30) — what a customer sees after opening the link a vendedor (or an
/// automatic pós-venda milestone, TASK-201) sent them. Never requires
/// login, never exposes `organizationId`/`customerId`/`sellerId` (see
/// `NpsSurveyPreview`'s own doc), and never reveals *why* an already
/// answered/expired/unknown link stopped working beyond a clear, generic
/// message (`tasks.md`: "nunca erro técnico cru"), same contract as
/// `CatalogSharePublicPage` (TASK-081).
class NpsResponsePage extends StatelessWidget {
  const NpsResponsePage({
    required this.token,
    required this.createBloc,
    super.key,
  });

  final String token;
  final NpsResponseBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NpsResponseBloc>(
      create: (_) => createBloc()..add(NpsResponseStarted(token: token)),
      child: const _NpsResponseView(),
    );
  }
}

class _NpsResponseView extends StatelessWidget {
  const _NpsResponseView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesquisa de satisfação')),
      body: SafeArea(
        child: BlocBuilder<NpsResponseBloc, NpsResponseState>(
          builder: (context, state) {
            return switch (state.status) {
              NpsResponsePageStatus.loading => const _LoadingView(),
              NpsResponsePageStatus.answerable => _AnswerableView(state: state),
              NpsResponsePageStatus.unavailable => _UnavailableView(
                state: state,
              ),
              NpsResponsePageStatus.error => _ErrorView(state: state),
            };
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.state});

  final NpsResponseState state;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(
      title: 'Não foi possível abrir esta pesquisa',
      message:
          state.failure?.message ?? 'Verifique sua conexão e tente novamente.',
      retryLabel: 'Tentar novamente',
      onRetry: () => context.read<NpsResponseBloc>().add(
        NpsResponseStarted(token: state.token),
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView({required this.state});

  final NpsResponseState state;

  @override
  Widget build(BuildContext context) {
    final (icon, title, description) = _messageFor(state.preview?.outcome);
    return AppEmptyState(icon: icon, title: title, description: description);
  }

  (IconData, String, String) _messageFor(NpsSurveyOutcome? outcome) {
    return switch (outcome) {
      NpsSurveyOutcome.answered => (
        Icons.check_circle_outline,
        'Obrigado por responder!',
        'Sua avaliação já foi registrada anteriormente.',
      ),
      NpsSurveyOutcome.expired => (
        Icons.schedule_outlined,
        'Esta pesquisa expirou',
        'O prazo para responder esta pesquisa já passou.',
      ),
      NpsSurveyOutcome.notFound || NpsSurveyOutcome.pending || null => (
        Icons.link_off,
        'Link inválido',
        'Verifique se o endereço foi copiado corretamente.',
      ),
    };
  }
}

class _AnswerableView extends StatelessWidget {
  const _AnswerableView({required this.state});

  final NpsResponseState state;

  @override
  Widget build(BuildContext context) {
    if (state.submissionStatus == NpsResponseSubmissionStatus.submitted) {
      return const AppEmptyState(
        icon: Icons.favorite_outline,
        title: 'Obrigado pela sua resposta!',
        description: 'Sua avaliação ajuda a melhorar nosso atendimento.',
      );
    }

    final preview = state.preview;
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (preview?.organizationName != null)
            Text(preview!.organizationName!, style: AppTypography.titleMedium),
          if (preview?.orderNumber != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing4),
            Text(
              'Pedido ${preview!.orderNumber}',
              style: AppTypography.bodyMedium.copyWith(color: colors.outline),
            ),
          ],
          const SizedBox(height: AppSpacing.spacing16),
          Text(
            'Em uma escala de 0 a 10, o quanto você recomendaria nossa '
            'empresa a um amigo ou colega?',
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.spacing12),
          _ScoreSelector(
            score: state.score,
            onChanged: (score) => context.read<NpsResponseBloc>().add(
              NpsResponseScoreChanged(score: score),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            label: 'Comentário (opcional)',
            hintText: 'Conte um pouco mais sobre sua experiência',
            maxLines: 3,
            maxLength: 1000,
            onChanged: (comment) => context.read<NpsResponseBloc>().add(
              NpsResponseCommentChanged(comment: comment),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          if (state.submissionStatus == NpsResponseSubmissionStatus.error)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
              child: Text(
                state.submissionFailure?.message ??
                    'Não foi possível enviar sua resposta. Tente novamente.',
                style: AppTypography.bodyMedium.copyWith(color: colors.error),
              ),
            ),
          AppButton(
            label: 'Enviar',
            isLoading:
                state.submissionStatus ==
                NpsResponseSubmissionStatus.submitting,
            onPressed: state.score == null
                ? null
                : () => context.read<NpsResponseBloc>().add(
                    const NpsResponseFormSubmitted(),
                  ),
          ),
          if (preview?.expiresAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing12),
            Text(
              'Disponível até '
              '${DateFormat('dd/MM/yyyy', 'pt_BR').format(preview!.expiresAt!.toLocal())}',
              style: AppTypography.bodySmall.copyWith(color: colors.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A 0-10 score picker built from [AppFilterChip] — no dedicated Design
/// System rating component exists yet for this single-use case; reusing the
/// existing selectable chip keeps every visual token (color, radius,
/// spacing, typography) sourced from the Design System instead of a
/// one-off widget.
class _ScoreSelector extends StatelessWidget {
  const _ScoreSelector({required this.score, required this.onChanged});

  final int? score;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.spacing8,
      runSpacing: AppSpacing.spacing8,
      children: List<Widget>.generate(11, (value) {
        return AppFilterChip(
          label: '$value',
          selected: score == value,
          onSelected: (_) => onChanged(value),
        );
      }),
    );
  }
}
