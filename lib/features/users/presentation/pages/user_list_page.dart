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

/// Lists every user of one Organization — search, role/status filters and
/// "carregar mais" pagination — with quick access to per-user administrative
/// actions (TASK-042).
///
/// Restricted to administrative profiles both here (via [PermissionBuilder],
/// gating the whole screen on [Capability.userChangeRole] — the capability
/// only OWNER/ADMIN ever hold) and, more importantly, on the backend: a bulk
/// `members` `list` query is denied by `firestore.rules` to anyone without
/// that same capability (TASK-042/TASK-030), so this UI-side check is
/// defense-in-depth/UX only, never the real authorization.
///
/// Never talks to `ListOrganizationUsersUseCase`/`MembershipRepository`
/// directly — every state transition goes through [UserListBloc], same
/// precedent as `InviteListPage`.
class UserListPage extends StatelessWidget {
  const UserListPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.onManageUser,
    this.onDeactivateUser,
    super.key,
  });

  final String organizationId;

  /// The signed-in user whose permission is being checked — never taken
  /// from anywhere else in the widget tree, same explicitness as
  /// `PermissionBuilder` itself requires.
  final String userId;
  final PermissionService permissionService;
  final UserListBloc Function() createBloc;

  /// Quick access to "gerenciar perfil/permissão" (TASK-043). `null` (the
  /// default) hides the action entirely — TASK-043's page/route does not
  /// exist yet, and a button that leads nowhere is worse than no button.
  final void Function(OrganizationUser user)? onManageUser;

  /// Quick access to "desativar usuário" (TASK-046). Same `null`-hides-the-
  /// action rationale as [onManageUser].
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
            onManageUser: onManageUser,
            onDeactivateUser: onDeactivateUser,
          ),
        );
      },
    );
  }
}

class _UserListView extends StatelessWidget {
  const _UserListView({this.onManageUser, this.onDeactivateUser});

  final void Function(OrganizationUser user)? onManageUser;
  final void Function(OrganizationUser user)? onDeactivateUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<UserListBloc, UserListState>(
        builder: (context, state) {
          final bloc = context.read<UserListBloc>();

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
                                  Text(user.email.isEmpty ? '—' : user.email),
                            ),
                            AppDataColumn(
                              label: 'Role',
                              cellBuilder: (context, user) =>
                                  Text(_roleLabel(user.roleName)),
                            ),
                            AppDataColumn(
                              label: 'Status',
                              cellBuilder: (context, user) => AppStatusBadge(
                                label: user.status == MembershipStatus.active
                                    ? 'Ativo'
                                    : 'Desativado',
                                variant: user.status == MembershipStatus.active
                                    ? AppStatusBadgeVariant.success
                                    : AppStatusBadgeVariant.neutral,
                              ),
                            ),
                            AppDataColumn(
                              label: 'Equipe',
                              cellBuilder: (context, user) => Text(
                                user.teamNames.isEmpty
                                    ? '—'
                                    : user.teamNames.join(', '),
                              ),
                            ),
                          ],
                          rowActions: <AppDataTableAction<OrganizationUser>>[
                            if (onManageUser != null)
                              AppDataTableAction<OrganizationUser>(
                                icon: Icons.manage_accounts_outlined,
                                semanticLabel: 'Gerenciar perfil/permissão',
                                onPressed: onManageUser!,
                              ),
                            if (onDeactivateUser != null)
                              AppDataTableAction<OrganizationUser>(
                                icon: Icons.block_outlined,
                                semanticLabel: 'Desativar usuário',
                                onPressed: onDeactivateUser!,
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

/// Shorter than [systemRoleNameLabel] (drops the parenthetical `(OWNER)`/
/// `(ADMIN)` suffix): the role filter chips live in the narrow
/// `AppAdminPageLayout` side panel, where the full descriptive label used
/// by `InviteUserPage`'s role picker would overflow.
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
