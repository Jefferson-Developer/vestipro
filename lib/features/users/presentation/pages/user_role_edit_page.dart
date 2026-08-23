import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../invites/presentation/pages/invite_user_page.dart'
    show systemRoleNameLabel;
import '../../../organizations/domain/value_objects/system_role_name.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/user_role_update_result.dart';
import '../bloc/user_role_edit_bloc.dart';
import '../bloc/user_role_edit_event.dart';
import '../bloc/user_role_edit_state.dart';

class UserRoleEditPage extends StatelessWidget {
  const UserRoleEditPage({
    required this.organizationId,
    required this.user,
    required this.createBloc,
    this.onRoleUpdated,
    super.key,
  });

  final String organizationId;
  final OrganizationUser user;
  final UserRoleEditBloc Function() createBloc;
  final void Function(UserRoleUpdateResult result)? onRoleUpdated;

  static Future<bool?> showBottomSheet({
    required BuildContext context,
    required String organizationId,
    required OrganizationUser user,
    required UserRoleEditBloc Function() createBloc,
    void Function(UserRoleUpdateResult result)? onRoleUpdated,
  }) {
    return AppBottomSheet.show<bool>(
      context: context,
      title: 'Alterar perfil',
      builder: (_) => _UserRoleEditScope(
        organizationId: organizationId,
        user: user,
        createBloc: createBloc,
        closeOnSuccess: true,
        onRoleUpdated: onRoleUpdated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alterar perfil')),
      body: _UserRoleEditScope(
        organizationId: organizationId,
        user: user,
        createBloc: createBloc,
        onRoleUpdated: onRoleUpdated,
      ),
    );
  }
}

class _UserRoleEditScope extends StatelessWidget {
  const _UserRoleEditScope({
    required this.organizationId,
    required this.user,
    required this.createBloc,
    this.closeOnSuccess = false,
    this.onRoleUpdated,
  });

  final String organizationId;
  final OrganizationUser user;
  final UserRoleEditBloc Function() createBloc;
  final bool closeOnSuccess;
  final void Function(UserRoleUpdateResult result)? onRoleUpdated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserRoleEditBloc>(
      create: (_) => createBloc()
        ..add(
          UserRoleEditEvent.started(organizationId: organizationId, user: user),
        ),
      child: _UserRoleEditView(
        closeOnSuccess: closeOnSuccess,
        onRoleUpdated: onRoleUpdated,
      ),
    );
  }
}

class _UserRoleEditView extends StatelessWidget {
  const _UserRoleEditView({required this.closeOnSuccess, this.onRoleUpdated});

  final bool closeOnSuccess;
  final void Function(UserRoleUpdateResult result)? onRoleUpdated;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserRoleEditBloc, UserRoleEditState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == UserRoleEditSubmissionStatus.failure) {
          final failure = state.failure;
          if (failure != null) {
            AppSnackbar.show(
              context,
              message: failure.message,
              variant: AppSnackbarVariant.error,
            );
          }
          return;
        }

        if (state.submissionStatus == UserRoleEditSubmissionStatus.success) {
          final result = state.result;
          if (result == null) {
            return;
          }
          onRoleUpdated?.call(result);
          AppSnackbar.show(
            context,
            message: 'Perfil atualizado com sucesso.',
            variant: AppSnackbarVariant.success,
          );
          if (closeOnSuccess) {
            Navigator.of(context).pop(true);
          }
        }
      },
      builder: (context, state) {
        return _UserRoleEditContent(state: state);
      },
    );
  }
}

class _UserRoleEditContent extends StatelessWidget {
  const _UserRoleEditContent({required this.state});

  final UserRoleEditState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == UserRoleEditLoadStatus.loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.assignableRoles.isEmpty) {
      return const AppErrorState(
        title: 'Sem permissão para alterar perfil',
        message:
            'Seu perfil não pode alterar a função deste usuário na organização.',
        icon: Icons.lock_outline,
      );
    }

    final user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }

    final isSubmitting =
        state.submissionStatus == UserRoleEditSubmissionStatus.submitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.spacing24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _UserRoleTargetSummary(
                user: user,
                currentRole: state.currentRole,
              ),
              const SizedBox(height: AppSpacing.spacing24),
              AppDropdown<SystemRoleName>(
                label: 'Nova função',
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
                selectedValues: state.selectedRole == null
                    ? const <SystemRoleName>{}
                    : <SystemRoleName>{state.selectedRole!},
                onChanged: (selected) {
                  if (selected.isNotEmpty) {
                    context.read<UserRoleEditBloc>().add(
                      UserRoleEditEvent.roleSelected(selected.first),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.spacing32),
              AppButton(
                label: 'Salvar alteração',
                leadingIcon: Icons.save_outlined,
                isLoading: isSubmitting,
                isDisabled: !state.canSubmit,
                expand: true,
                onPressed: () => _handleSubmit(context, state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(
    BuildContext context,
    UserRoleEditState state,
  ) async {
    if (state.requiresConfirmation) {
      final confirmed = await AppConfirmationDialog.show(
        context: context,
        title: 'Confirmar alteração sensível?',
        message:
            'Esta alteração muda um perfil administrativo crítico. Confirme '
            'para continuar.',
        confirmLabel: 'Confirmar alteração',
      );
      if (!confirmed || !context.mounted) {
        return;
      }
    }

    if (!context.mounted) {
      return;
    }
    context.read<UserRoleEditBloc>().add(const UserRoleEditEvent.submitted());
  }
}

class _UserRoleTargetSummary extends StatelessWidget {
  const _UserRoleTargetSummary({required this.user, required this.currentRole});

  final OrganizationUser user;
  final SystemRoleName? currentRole;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final email = user.email.isEmpty ? 'Sem e-mail cadastrado' : user.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          user.name,
          style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          email,
          style: AppTypography.bodyMedium.copyWith(color: colors.outline),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppStatusBadge(
          label: currentRole == null
              ? user.roleName
              : 'Atual: ${systemRoleNameLabel(currentRole!)}',
          variant: AppStatusBadgeVariant.neutral,
        ),
      ],
    );
  }
}
