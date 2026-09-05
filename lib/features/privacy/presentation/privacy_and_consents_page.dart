import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/entities/consent_record.dart';
import 'consent_management_cubit.dart';

class PrivacyAndConsentsPage extends StatelessWidget {
  const PrivacyAndConsentsPage({
    required this.createCubit,
    required this.onPolicyDocumentsTap,
    super.key,
  });

  final ConsentManagementCubit Function() createCubit;
  final VoidCallback onPolicyDocumentsTap;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = createCubit();
      unawaited(cubit.load());
      return cubit;
    },
    child: _PrivacyAndConsentsView(onPolicyDocumentsTap: onPolicyDocumentsTap),
  );
}

class _PrivacyAndConsentsView extends StatelessWidget {
  const _PrivacyAndConsentsView({required this.onPolicyDocumentsTap});
  final VoidCallback onPolicyDocumentsTap;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ConsentManagementCubit, ConsentManagementState>(
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Privacidade e consentimentos')),
          body: SafeArea(
            child: switch (state.status) {
              ConsentManagementStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              ConsentManagementStatus.failure => AppErrorState(
                title: 'Não foi possível carregar seus consentimentos',
                message: state.failure?.message ?? 'Tente novamente.',
                retryLabel: 'Tentar novamente',
                onRetry: context.read<ConsentManagementCubit>().load,
              ),
              ConsentManagementStatus.ready => _ConsentContent(
                state: state,
                onPolicyDocumentsTap: onPolicyDocumentsTap,
              ),
            },
          ),
        ),
      );
}

class _ConsentContent extends StatelessWidget {
  const _ConsentContent({
    required this.state,
    required this.onPolicyDocumentsTap,
  });
  final ConsentManagementState state;
  final VoidCallback onPolicyDocumentsTap;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        children: <Widget>[
          Text(
            'Consentimentos opcionais',
            style: AppTypography.headlineMedium.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Nada vem ativado por padrão. Você pode conceder ou revogar cada finalidade com um toque, a qualquer momento.',
            style: AppTypography.bodyLarge.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          for (final purpose in ConsentPurpose.values) ...<Widget>[
            _ConsentTile(
              purpose: purpose,
              record: state.effective[purpose],
              updating: state.updating.contains(purpose),
            ),
            const SizedBox(height: AppSpacing.spacing12),
          ],
          const SizedBox(height: AppSpacing.spacing12),
          const Divider(),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            'Documentos legais',
            style: AppTypography.titleLarge.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'O aceite da Política de Privacidade e dos Termos de Uso é separado destes consentimentos opcionais.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppButton(
            label: 'Revisar política e termos',
            variant: AppButtonVariant.secondary,
            onPressed: onPolicyDocumentsTap,
          ),
        ],
      ),
    ),
  );
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.purpose,
    required this.record,
    required this.updating,
  });
  final ConsentPurpose purpose;
  final ConsentRecord? record;
  final bool updating;

  @override
  Widget build(BuildContext context) {
    final granted = record?.granted ?? false;
    return Card(
      child: SwitchListTile.adaptive(
        key: ValueKey<String>('consent-${purpose.code}'),
        value: granted,
        onChanged: updating
            ? null
            : (value) => context.read<ConsentManagementCubit>().setConsent(
                purpose,
                value,
              ),
        title: Text(purpose.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: AppSpacing.spacing4),
            Text(purpose.description),
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              record == null
                  ? 'Não concedido'
                  : '${granted ? 'Concedido' : 'Revogado'} em ${_dateTime(record!.recordedAt)}',
              style: AppTypography.bodySmall.copyWith(
                color: context.colors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} às ${two(local.hour)}:${two(local.minute)}';
  }
}
