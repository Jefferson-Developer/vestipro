import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/invite.dart';
import '../../domain/value_objects/invite_status.dart';
import 'invite_user_page.dart' show systemRoleNameLabel;
import '../bloc/invite_list_bloc.dart';
import '../bloc/invite_list_event.dart';
import '../bloc/invite_list_state.dart';

/// Lists pending/expired invites of one Organization, letting an OWNER/
/// ADMIN resend or revoke each one (TASK-039).
///
/// Never talks to `ListPendingInvitesUseCase`/`ResendInviteUseCase`/
/// `RevokeInviteUseCase` directly — every action is dispatched to
/// [InviteListBloc].
class InviteListPage extends StatelessWidget {
  const InviteListPage({
    required this.organizationId,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final InviteListBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InviteListBloc>(
      create: (_) => createBloc()..add(InviteListEvent.started(organizationId)),
      child: const _InviteListView(),
    );
  }
}

class _InviteListView extends StatelessWidget {
  const _InviteListView();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Convites pendentes')),
      body: BlocConsumer<InviteListBloc, InviteListState>(
        listenWhen: (previous, current) =>
            previous.actionFailure != current.actionFailure ||
            previous.lastResendResult != current.lastResendResult,
        listener: (context, state) {
          final actionFailure = state.actionFailure;
          if (actionFailure != null) {
            AppSnackbar.show(
              context,
              message: actionFailure.message,
              variant: AppSnackbarVariant.error,
            );
            return;
          }
          final resendResult = state.lastResendResult;
          if (resendResult != null) {
            AppSnackbar.show(
              context,
              message: 'Convite reenviado para ${resendResult.invite.email}.',
              variant: AppSnackbarVariant.success,
            );
          }
        },
        builder: (context, state) {
          return switch (state.loadStatus) {
            InviteListLoadStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            InviteListLoadStatus.failure => AppErrorState(
              title: 'Não foi possível carregar os convites',
              message:
                  state.loadFailure?.message ?? 'Tente novamente em breve.',
              retryLabel: 'Tentar novamente',
              onRetry: () => context.read<InviteListBloc>().add(
                const InviteListEvent.refreshRequested(),
              ),
            ),
            InviteListLoadStatus.ready when state.invites.isEmpty =>
              const AppEmptyState(
                title: 'Nenhum convite pendente',
                description:
                    'Convites enviados para novos colaboradores aparecem '
                    'aqui até serem aceitos, expirarem ou serem revogados.',
              ),
            InviteListLoadStatus.ready => _InviteListContent(state: state),
          };
        },
      ),
    );
  }
}

class _InviteListContent extends StatelessWidget {
  const _InviteListContent({required this.state});

  final InviteListState state;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      itemCount: state.invites.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.spacing12),
      itemBuilder: (context, index) {
        final invite = state.invites[index];
        return _InviteCard(
          invite: invite,
          isProcessing: state.processingInviteId == invite.id,
        );
      },
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite, required this.isProcessing});

  final Invite invite;
  final bool isProcessing;

  AppStatusBadgeVariant get _statusVariant => switch (invite.status) {
    InviteStatus.pending => AppStatusBadgeVariant.info,
    InviteStatus.expired => AppStatusBadgeVariant.warning,
    InviteStatus.accepted => AppStatusBadgeVariant.success,
    InviteStatus.revoked => AppStatusBadgeVariant.neutral,
  };

  String get _statusLabel => switch (invite.status) {
    InviteStatus.pending => 'Pendente',
    InviteStatus.expired => 'Expirado',
    InviteStatus.accepted => 'Aceito',
    InviteStatus.revoked => 'Revogado',
  };

  Future<void> _confirmRevoke(BuildContext context) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Revogar convite?',
      message:
          'O link enviado para ${invite.email} deixa de funcionar '
          'imediatamente. Esta ação não pode ser desfeita.',
      confirmLabel: 'Revogar',
    );
    if (confirmed && context.mounted) {
      context.read<InviteListBloc>().add(
        InviteListEvent.revokeRequested(invite.id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canManage =
        invite.status == InviteStatus.pending ||
        invite.status == InviteStatus.expired;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  invite.email,
                  style: AppTypography.bodyLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              AppStatusBadge(label: _statusLabel, variant: _statusVariant),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            systemRoleNameLabel(invite.roleName),
            style: AppTypography.bodyMedium.copyWith(color: colors.outline),
          ),
          if (canManage) ...<Widget>[
            const SizedBox(height: AppSpacing.spacing12),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppButton(
                    label: 'Reenviar',
                    variant: AppButtonVariant.secondary,
                    isLoading: isProcessing,
                    onPressed: isProcessing
                        ? null
                        : () => context.read<InviteListBloc>().add(
                            InviteListEvent.resendRequested(invite.id),
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing12),
                Expanded(
                  child: AppButton(
                    label: 'Revogar',
                    variant: AppButtonVariant.destructive,
                    isDisabled: isProcessing,
                    onPressed: () => _confirmRevoke(context),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
