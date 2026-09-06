import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';
import '../domain/entities/consent_record.dart';
import '../domain/entities/personal_data_export.dart';
import '../domain/usecases/request_account_deletion.dart';
import 'account_deletion_cubit.dart';
import 'consent_management_cubit.dart';
import 'personal_data_export_cubit.dart';

class PrivacyAndConsentsPage extends StatelessWidget {
  const PrivacyAndConsentsPage({
    required this.createCubit,
    required this.createExportCubit,
    this.createDeletionCubit,
    required this.onPolicyDocumentsTap,
    super.key,
  });

  final ConsentManagementCubit Function() createCubit;
  final PersonalDataExportCubit Function() createExportCubit;
  final AccountDeletionCubit Function()? createDeletionCubit;
  final VoidCallback onPolicyDocumentsTap;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<ConsentManagementCubit>(
        create: (_) {
          final cubit = createCubit();
          unawaited(cubit.load());
          return cubit;
        },
      ),
      BlocProvider<PersonalDataExportCubit>(
        create: (_) {
          final cubit = createExportCubit();
          unawaited(cubit.load());
          return cubit;
        },
      ),
      if (createDeletionCubit != null)
        BlocProvider<AccountDeletionCubit>(
          create: (_) => createDeletionCubit!(),
        ),
    ],
    child: _PrivacyAndConsentsView(
      onPolicyDocumentsTap: onPolicyDocumentsTap,
      showAccountDeletion: createDeletionCubit != null,
    ),
  );
}

class _PrivacyAndConsentsView extends StatelessWidget {
  const _PrivacyAndConsentsView({
    required this.onPolicyDocumentsTap,
    required this.showAccountDeletion,
  });
  final VoidCallback onPolicyDocumentsTap;
  final bool showAccountDeletion;

  @override
  Widget build(BuildContext context) =>
      BlocListener<PersonalDataExportCubit, PersonalDataExportState>(
        listenWhen: (previous, current) =>
            previous.download != current.download,
        listener: (context, state) async {
          final download = state.download;
          if (download == null) return;
          await Clipboard.setData(ClipboardData(text: download.url.toString()));
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Link seguro copiado. Ele expira em 15 minutos.'),
            ),
          );
        },
        child: BlocBuilder<ConsentManagementCubit, ConsentManagementState>(
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
                  showAccountDeletion: showAccountDeletion,
                ),
              },
            ),
          ),
        ),
      );
}

class _ConsentContent extends StatelessWidget {
  const _ConsentContent({
    required this.state,
    required this.onPolicyDocumentsTap,
    required this.showAccountDeletion,
  });
  final ConsentManagementState state;
  final VoidCallback onPolicyDocumentsTap;
  final bool showAccountDeletion;

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
          const SizedBox(height: AppSpacing.spacing24),
          const Divider(),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            'Seus dados pessoais',
            style: AppTypography.titleLarge.copyWith(
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            'Solicite uma cópia em JSON dos seus dados. Clientes e dados pessoais de outras pessoas não são incluídos.',
            style: AppTypography.bodyMedium.copyWith(
              color: context.colors.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          BlocBuilder<PersonalDataExportCubit, PersonalDataExportState>(
            builder: (context, exportState) =>
                _PersonalDataExportSection(state: exportState),
          ),
          if (showAccountDeletion) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing24),
            const Divider(),
            const SizedBox(height: AppSpacing.spacing12),
            const _AccountDeletionSection(),
          ],
        ],
      ),
    ),
  );
}

class _AccountDeletionSection extends StatelessWidget {
  const _AccountDeletionSection();

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<AccountDeletionCubit, AccountDeletionState>(
    listener: (context, state) {
      if (state.status == AccountDeletionStatus.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta excluída e dados locais removidos.'),
          ),
        );
      }
    },
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Excluir conta e dados',
          style: AppTypography.titleLarge.copyWith(color: context.colors.error),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Text(
          'Esta ação remove seu perfil, vínculos, consentimentos, notificações, tokens e dados do dispositivo. Pedidos/documentos fiscais e auditoria são retidos apenas por obrigação legal, com sua identidade anonimizada para os demais usuários.',
          style: AppTypography.bodyMedium.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        AppButton(
          key: const ValueKey<String>('request-account-deletion'),
          label: state.status == AccountDeletionStatus.submitting
              ? 'Excluindo…'
              : 'Excluir minha conta',
          variant: AppButtonVariant.secondary,
          onPressed: state.status == AccountDeletionStatus.submitting
              ? null
              : () => _confirmAccountDeletion(context),
        ),
        if (state.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            state.failure!.message,
            key: const ValueKey<String>('account-deletion-error'),
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final phrase = await showDialog<String>(
      context: context,
      builder: (_) => const _AccountDeletionDialog(),
    );
    if (phrase != null && context.mounted) {
      await context.read<AccountDeletionCubit>().submit(phrase);
    }
  }
}

class _AccountDeletionDialog extends StatefulWidget {
  const _AccountDeletionDialog();

  @override
  State<_AccountDeletionDialog> createState() => _AccountDeletionDialogState();
}

class _AccountDeletionDialogState extends State<_AccountDeletionDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Excluir conta permanentemente?'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Entre novamente caso solicitado. Para confirmar, digite exatamente:',
          ),
          const SizedBox(height: AppSpacing.spacing8),
          const SelectableText(RequestAccountDeletion.confirmationPhrase),
          const SizedBox(height: AppSpacing.spacing12),
          TextField(
            key: const ValueKey<String>('account-deletion-confirmation'),
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Frase de confirmação',
            ),
          ),
        ],
      ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey<String>('confirm-account-deletion'),
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Excluir permanentemente'),
      ),
    ],
  );
}

class _PersonalDataExportSection extends StatelessWidget {
  const _PersonalDataExportSection({required this.state});
  final PersonalDataExportState state;

  @override
  Widget build(BuildContext context) {
    final latest = state.exports.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (latest != null) ...<Widget>[
          Card(
            child: ListTile(
              key: const ValueKey<String>('personal-data-export-status'),
              leading: Icon(_icon(latest.status)),
              title: Text(_label(latest.status)),
              subtitle: Text(
                latest.status == PersonalDataExportStatus.ready &&
                        latest.expiresAt != null
                    ? 'Disponível até ${_dateTime(latest.expiresAt!)}'
                    : 'Solicitado em ${_dateTime(latest.requestedAt)}',
              ),
              trailing: latest.canDownload
                  ? TextButton(
                      key: const ValueKey<String>(
                        'personal-data-export-download',
                      ),
                      onPressed: () => context
                          .read<PersonalDataExportCubit>()
                          .download(latest.id),
                      child: const Text('Copiar link'),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing12),
        ],
        AppButton(
          key: const ValueKey<String>('request-personal-data-export'),
          label: state.requesting ? 'Solicitando…' : 'Solicitar meus dados',
          onPressed: state.requesting
              ? null
              : context.read<PersonalDataExportCubit>().request,
        ),
        if (state.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            state.failure!.message,
            style: AppTypography.bodySmall.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
      ],
    );
  }

  String _label(PersonalDataExportStatus status) => switch (status) {
    PersonalDataExportStatus.requested => 'Solicitação recebida',
    PersonalDataExportStatus.processing => 'Preparando seus dados',
    PersonalDataExportStatus.ready => 'Exportação pronta',
    PersonalDataExportStatus.expired => 'Exportação expirada',
    PersonalDataExportStatus.failed => 'Falha ao preparar exportação',
  };

  IconData _icon(PersonalDataExportStatus status) => switch (status) {
    PersonalDataExportStatus.requested => Icons.schedule_outlined,
    PersonalDataExportStatus.processing => Icons.sync,
    PersonalDataExportStatus.ready => Icons.download_done_outlined,
    PersonalDataExportStatus.expired => Icons.timer_off_outlined,
    PersonalDataExportStatus.failed => Icons.error_outline,
  };

  String _dateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} às ${two(local.hour)}:${two(local.minute)}';
  }
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
