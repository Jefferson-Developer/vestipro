import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../invites/domain/role_hierarchy.dart'
    show systemRoleNameFromCode;
import '../../../invites/presentation/pages/invite_user_page.dart'
    show systemRoleNameLabel;
import '../../../organizations/organizations.dart';
import '../../domain/entities/organization_user.dart';
import '../bloc/user_list_bloc.dart';
import '../bloc/user_list_event.dart';
import '../bloc/user_list_state.dart';
import '../bloc/user_role_edit_bloc.dart';
import 'user_role_edit_page.dart';

/// Lists every user of one Organization with administrative actions
/// (TASK-042/TASK-046). The UI never writes Firestore directly: role edits
/// and access changes go through BLoCs/use cases backed by Cloud Functions.
class UserListPage extends StatelessWidget {
  const UserListPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.createRoleEditBloc,
    this.onManageUser,
    this.onDeactivateUser,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final UserListBloc Function() createBloc;
  final UserRoleEditBloc Function()? createRoleEditBloc;

  /// Optional override for tests/shells embedding this page. The default
  /// opens the official TASK-043 bottom sheet when [createRoleEditBloc] is
  /// provided.
  final void Function(OrganizationUser user)? onManageUser;

  /// Optional override for the TASK-046 status action. The default shows the
  /// confirmation dialog and dispatches [UserListEvent.accessStatusChangeRequested].
  final void Function(OrganizationUser user)? onDeactivateUser;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.userChangeRole,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<UserListBloc>(
          create: (_) =>
              createBloc()..add(UserListEvent.started(organizationId)),
          child: _UserListView(
            organizationId: organizationId,
            createRoleEditBloc: createRoleEditBloc,
            onManageUser: onManageUser,
            onDeactivateUser: onDeactivateUser,
          ),
        );
      },
    );
  }
}

class _UserListView extends StatelessWidget {
  const _UserListView({
    required this.organizationId,
    this.createRoleEditBloc,
    this.onManageUser,
    this.onDeactivateUser,
  });

  final String organizationId;
  final UserRoleEditBloc Function()? createRoleEditBloc;
  final void Function(OrganizationUser user)? onManageUser;
  final void Function(OrganizationUser user)? onDeactivateUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<UserListBloc, UserListState>(
        listenWhen: (previous, current) =>
            previous.accessMutationStatus != current.accessMutationStatus,
        listener: _listenToAccessMutation,
        builder: (context, state) {
          final bloc = context.read<UserListBloc>();
          final manageUser =
              onManageUser ??
              (createRoleEditBloc == null
                  ? null
                  : (OrganizationUser user) => _openRoleEditor(
                      context: context,
                      bloc: bloc,
                      user: user,
                    ));
          final changeAccess =
              onDeactivateUser ??
              (OrganizationUser user) => _confirmAndChangeAccess(
                context: context,
                bloc: bloc,
                user: user,
              );

          return AppAdminPageLayout(
            title: 'Usuários',
            filtersBuilder: (context) => _UserListFilters(state: state),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por nome ou e-mail',
                  onSearch: (query) =>
                      bloc.add(UserListEvent.searchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppDataTable<OrganizationUser>(
                          status: _tableStatus(state),
                          rows: state.visibleUsers,
                          rowIdBuilder: (user) => user.userId,
                          emptyTitle: 'Nenhum usuário encontrado',
                          emptyDescription:
                              'Ajuste a busca ou os filtros aplicados.',
                          errorTitle: 'Não foi possível carregar os usuários',
                          errorMessage:
                              state.loadFailure?.message ??
                              'Tente novamente em breve.',
                          retryLabel: 'Tentar novamente',
                          onRetry: () =>
                              bloc.add(const UserListEvent.refreshRequested()),
                          mobileCardTitleBuilder: (context, user) =>
                              Text(user.name),
                          columns: <AppDataColumn<OrganizationUser>>[
                            AppDataColumn(
                              label: 'Nome',
                              cellBuilder: (context, user) => Text(user.name),
                            ),
                            AppDataColumn(
                              label: 'E-mail',
                              cellBuilder: (context, user) =>
                                  Text(user.email.isEmpty ? '-' : user.email),
                            ),
                            AppDataColumn(
                              label: 'Role',
                              cellBuilder: (context, user) =>
                                  Text(_roleLabel(user.roleName)),
                            ),
                            AppDataColumn(
                              label: 'Status',
                              cellBuilder: (context, user) => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: AppStatusBadge(
                                  label: user.status == MembershipStatus.active
                                      ? 'Ativo'
                                      : 'Desativado',
                                  variant:
                                      user.status == MembershipStatus.active
                                      ? AppStatusBadgeVariant.success
                                      : AppStatusBadgeVariant.neutral,
                                ),
                              ),
                            ),
                            AppDataColumn(
                              label: 'Equipe',
                              cellBuilder: (context, user) => Text(
                                user.teamNames.isEmpty
                                    ? '-'
                                    : user.teamNames.join(', '),
                              ),
                            ),
                          ],
                          rowActions: <AppDataTableAction<OrganizationUser>>[
                            if (manageUser != null)
                              AppDataTableAction<OrganizationUser>(
                                icon: Icons.manage_accounts_outlined,
                                semanticLabel: 'Gerenciar perfil/permissão',
                                onPressed: manageUser,
                              ),
                            AppDataTableAction<OrganizationUser>(
                              icon: Icons.block_outlined,
                              semanticLabel: 'Desativar usuário',
                              iconBuilder: (user) =>
                                  user.status == MembershipStatus.active
                                  ? Icons.block_outlined
                                  : Icons.restore_outlined,
                              semanticLabelBuilder: (user) =>
                                  user.status == MembershipStatus.active
                                  ? 'Desativar usuário'
                                  : 'Reativar usuário',
                              onPressed: changeAccess,
                            ),
                          ],
                        ),
                        if (_tableStatus(state) ==
                            AppDataTableStatus.idle) ...<Widget>[
                          const SizedBox(height: AppSpacing.spacing8),
                          AppPagination(
                            hasMore: state.hasMore,
                            onLoadMore: () => bloc.add(
                              const UserListEvent.loadMoreRequested(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _listenToAccessMutation(BuildContext context, UserListState state) {
    switch (state.accessMutationStatus) {
      case UserListAccessMutationStatus.success:
        final result = state.accessMutationResult;
        if (result == null) return;
        final deactivated = result.status == MembershipStatus.inactive;
        AppSnackbar.show(
          context,
          message: deactivated
              ? 'Usuário desativado. O histórico foi preservado.'
              : 'Usuário reativado.',
          variant: AppSnackbarVariant.success,
        );
      case UserListAccessMutationStatus.failure:
        AppSnackbar.show(
          context,
          message:
              state.accessMutationFailure?.message ??
              'Não foi possível alterar o acesso do usuário.',
          variant: AppSnackbarVariant.error,
        );
      case UserListAccessMutationStatus.idle:
      case UserListAccessMutationStatus.submitting:
        break;
    }
  }

  Future<void> _confirmAndChangeAccess({
    required BuildContext context,
    required UserListBloc bloc,
    required OrganizationUser user,
  }) async {
    final isDeactivation = user.status == MembershipStatus.active;
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: isDeactivation ? 'Desativar usuário?' : 'Reativar usuário?',
      message: isDeactivation
          ? 'O acesso deste usuário à organização será bloqueado, mas pedidos, atividades CRM, vínculos de carteira e auditoria permanecerão preservados no histórico.'
          : 'O acesso deste usuário à organização será restaurado e a reativação ficará registrada na auditoria.',
      confirmLabel: isDeactivation ? 'Desativar' : 'Reativar',
    );
    if (confirmed && context.mounted) {
      bloc.add(UserListEvent.accessStatusChangeRequested(user));
    }
  }

  Future<void> _openRoleEditor({
    required BuildContext context,
    required UserListBloc bloc,
    required OrganizationUser user,
  }) async {
    final updated = await UserRoleEditPage.showBottomSheet(
      context: context,
      organizationId: organizationId,
      user: user,
      createBloc: createRoleEditBloc!,
    );

    if (updated == true && context.mounted) {
      bloc.add(const UserListEvent.refreshRequested());
    }
  }

  AppDataTableStatus _tableStatus(UserListState state) {
    return switch (state.loadStatus) {
      UserListLoadStatus.loading => AppDataTableStatus.loading,
      UserListLoadStatus.failure => AppDataTableStatus.error,
      UserListLoadStatus.ready =>
        state.filteredUsers.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }
}

String _roleLabel(String roleName) {
  final systemRole = systemRoleNameFromCode(roleName);
  return systemRole == null ? roleName : systemRoleNameLabel(systemRole);
}

String _roleFilterLabel(SystemRoleName role) {
  return switch (role) {
    SystemRoleName.owner => 'Proprietário',
    SystemRoleName.admin => 'Administrador',
    _ => systemRoleNameLabel(role),
  };
}

class _UserListFilters extends StatelessWidget {
  const _UserListFilters({required this.state});

  final UserListState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<UserListBloc>();
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Role',
          style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: SystemRoleName.values
              .map((role) {
                final selected = state.roleFilter == role.code;
                return AppFilterChip(
                  label: _roleFilterLabel(role),
                  selected: selected,
                  onSelected: (nextSelected) => bloc.add(
                    UserListEvent.roleFilterChanged(
                      nextSelected ? role.code : null,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: AppSpacing.spacing24),
        Text(
          'Status',
          style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: MembershipStatus.values
              .map((status) {
                final selected = state.statusFilter == status;
                return AppFilterChip(
                  label: status == MembershipStatus.active
                      ? 'Ativo'
                      : 'Desativado',
                  selected: selected,
                  onSelected: (nextSelected) => bloc.add(
                    UserListEvent.statusFilterChanged(
                      nextSelected ? status : null,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
