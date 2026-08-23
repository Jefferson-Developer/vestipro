import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../bloc/invite_form_bloc.dart';
import '../bloc/invite_form_event.dart';
import '../bloc/invite_form_state.dart';

/// Human-readable label for [SystemRoleName], used by every role picker in
/// this feature. Kept here (not on the enum itself) so `domain/` stays free
/// of user-facing/i18n-ready strings.
String systemRoleNameLabel(SystemRoleName role) {
  return switch (role) {
    SystemRoleName.owner => 'Proprietário (OWNER)',
    SystemRoleName.admin => 'Administrador (ADMIN)',
    SystemRoleName.salesManager => 'Gerente comercial',
    SystemRoleName.salesRep => 'Representante',
    SystemRoleName.salesAssistant => 'Assistente comercial',
    SystemRoleName.finance => 'Financeiro',
    SystemRoleName.readOnly => 'Somente leitura',
  };
}

/// Lets an OWNER/ADMIN invite a new collaborator into an Organization
/// (TASK-039) — e-mail, role (restricted to what the signed-in user is
/// allowed to assign) and an optional message.
///
/// Never talks to `CreateInviteUseCase`/`MembershipRepository` directly:
/// every field edit and the final submit are dispatched to [InviteFormBloc],
/// same rationale as `OnboardingWizardPage` (TASK-038).
class InviteUserPage extends StatelessWidget {
  const InviteUserPage({
    required this.organizationId,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final InviteFormBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InviteFormBloc>(
      create: (_) => createBloc()..add(InviteFormEvent.started(organizationId)),
      child: const _InviteUserView(),
    );
  }
}

class _InviteUserView extends StatefulWidget {
  const _InviteUserView();

  @override
  State<_InviteUserView> createState() => _InviteUserViewState();
}

class _InviteUserViewState extends State<_InviteUserView> {
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Convidar usuário')),
      body: BlocConsumer<InviteFormBloc, InviteFormState>(
        listenWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus,
        listener: (context, state) {
          if (state.submissionStatus == InviteFormSubmissionStatus.failure) {
            final failure = state.failure;
            if (failure != null) {
              AppSnackbar.show(
                context,
                message: failure.message,
                variant: AppSnackbarVariant.error,
              );
            }
          }
        },
        builder: (context, state) {
          if (state.loadStatus == InviteFormLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.submissionStatus == InviteFormSubmissionStatus.success) {
            return _InviteSentContent(state: state);
          }
          return _InviteFormContent(
            state: state,
            emailController: _emailController,
            messageController: _messageController,
          );
        },
      ),
    );
  }
}

class _InviteFormContent extends StatelessWidget {
  const _InviteFormContent({
    required this.state,
    required this.emailController,
    required this.messageController,
  });

  final InviteFormState state;
  final TextEditingController emailController;
  final TextEditingController messageController;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<InviteFormBloc>();
    final isSubmitting =
        state.submissionStatus == InviteFormSubmissionStatus.submitting;
    final canInvite = state.assignableRoles.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!canInvite)
                AppErrorState(
                  title: 'Sem permissão',
                  message:
                      'Apenas OWNER/ADMIN podem convidar novos usuários '
                      'para esta organização.',
                )
              else ...<Widget>[
                AppTextField(
                  controller: emailController,
                  label: 'E-mail do convidado',
                  isRequired: true,
                  errorText: state.emailError,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) =>
                      bloc.add(InviteFormEvent.emailChanged(value)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                AppDropdown<SystemRoleName>(
                  label: 'Função',
                  isRequired: true,
                  errorText: state.roleError,
                  closeSemanticLabel: 'Fechar seleção de função',
                  options: state.assignableRoles
                      .map(
                        (role) => AppDropdownOption<SystemRoleName>(
                          value: role,
                          label: systemRoleNameLabel(role),
                        ),
                      )
                      .toList(growable: false),
                  selectedValues: state.role == null
                      ? const <SystemRoleName>{}
                      : <SystemRoleName>{state.role!},
                  onChanged: (selected) {
                    if (selected.isNotEmpty) {
                      bloc.add(InviteFormEvent.roleSelected(selected.first));
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.spacing16),
                AppTextField(
                  controller: messageController,
                  label: 'Mensagem (opcional)',
                  maxLines: 3,
                  onChanged: (value) =>
                      bloc.add(InviteFormEvent.messageChanged(value)),
                ),
                const SizedBox(height: AppSpacing.spacing32),
                AppButton(
                  label: 'Enviar convite',
                  isLoading: isSubmitting,
                  expand: true,
                  onPressed: isSubmitting
                      ? null
                      : () => bloc.add(const InviteFormEvent.submitted()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteSentContent extends StatelessWidget {
  const _InviteSentContent({required this.state});

  final InviteFormState state;

  @override
  Widget build(BuildContext context) {
    final issuedInvite = state.issuedInvite;
    if (issuedInvite == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Convite enviado para ${issuedInvite.invite.email}',
                style: AppTypography.titleMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                'Não há envio automático de e-mail configurado ainda — '
                'copie e compartilhe o link abaixo manualmente com o '
                'convidado. Ele deixa de funcionar quando o convite for '
                'reenviado, revogado, expirar ou for aceito.',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.outline,
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              SelectableText(
                'https://app.vestipro.com.br/invite/${issuedInvite.token}',
                style: AppTypography.bodyMedium.copyWith(
                  color: context.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
