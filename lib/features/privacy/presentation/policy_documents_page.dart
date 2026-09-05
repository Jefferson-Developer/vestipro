import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/entities/policy_document.dart';
import 'policy_acceptance_cubit.dart';

class PolicyDocumentsPage extends StatelessWidget {
  const PolicyDocumentsPage({
    required this.createCubit,
    required this.requireAcceptance,
    this.onAccepted,
    super.key,
  });

  final PolicyAcceptanceCubit Function() createCubit;
  final bool requireAcceptance;
  final VoidCallback? onAccepted;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = createCubit();
      unawaited(cubit.load());
      return cubit;
    },
    child: _PolicyDocumentsView(
      requireAcceptance: requireAcceptance,
      onAccepted: onAccepted,
    ),
  );
}

class _PolicyDocumentsView extends StatelessWidget {
  const _PolicyDocumentsView({
    required this.requireAcceptance,
    this.onAccepted,
  });
  final bool requireAcceptance;
  final VoidCallback? onAccepted;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PolicyAcceptanceCubit, PolicyAcceptanceState>(
      listenWhen: (previous, current) =>
          previous.status != PolicyAcceptanceStatus.accepted &&
          current.status == PolicyAcceptanceStatus.accepted,
      listener: (_, _) => onAccepted?.call(),
      builder: (context, state) => Scaffold(
        appBar: requireAcceptance
            ? null
            : AppBar(title: const Text('Privacidade e termos')),
        body: SafeArea(
          child: switch (state.status) {
            PolicyAcceptanceStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            PolicyAcceptanceStatus.failure => AppErrorState(
              title: 'Não foi possível carregar os documentos',
              message: state.failure?.message ?? 'Tente novamente.',
              retryLabel: 'Tentar novamente',
              onRetry: context.read<PolicyAcceptanceCubit>().load,
            ),
            _ => _DocumentsContent(
              state: state,
              requireAcceptance: requireAcceptance,
            ),
          },
        ),
      ),
    );
  }
}

class _DocumentsContent extends StatelessWidget {
  const _DocumentsContent({
    required this.state,
    required this.requireAcceptance,
  });
  final PolicyAcceptanceState state;
  final bool requireAcceptance;

  @override
  Widget build(BuildContext context) {
    final accepting = state.status == PolicyAcceptanceStatus.accepting;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          children: <Widget>[
            if (requireAcceptance) ...<Widget>[
              Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: context.colors.primary,
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Text(
                'Antes de continuar',
                textAlign: TextAlign.center,
                style: AppTypography.headlineMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Leia e aceite as versões vigentes. Uma nova versão sempre exige um novo aceite explícito.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge.copyWith(
                  color: context.colors.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
            ],
            for (final document in state.documents) ...<Widget>[
              _PolicySection(document: document),
              const SizedBox(height: AppSpacing.spacing24),
            ],
            if (requireAcceptance &&
                state.status != PolicyAcceptanceStatus.accepted) ...<Widget>[
              AppCheckbox(
                key: const ValueKey('policy-acceptance-checkbox'),
                value: state.acceptanceChecked,
                isDisabled: accepting,
                label:
                    'Li e aceito a Política de Privacidade e os Termos de Uso nas versões exibidas acima.',
                onChanged: context
                    .read<PolicyAcceptanceCubit>()
                    .setAcceptanceChecked,
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppButton(
                key: const ValueKey('policy-acceptance-button'),
                label: 'Aceitar e continuar',
                expand: true,
                isLoading: accepting,
                onPressed: !state.acceptanceChecked || accepting
                    ? null
                    : context.read<PolicyAcceptanceCubit>().submitAcceptance,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({required this.document});
  final PolicyDocument document;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          document.type.label,
          style: AppTypography.titleLarge.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          'Versão ${document.version} • publicada em ${_date(document.publishedAt)}',
          style: AppTypography.bodySmall.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        SelectableText(
          document.content,
          style: AppTypography.bodyLarge.copyWith(
            color: context.colors.onSurface,
          ),
        ),
      ],
    ),
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
