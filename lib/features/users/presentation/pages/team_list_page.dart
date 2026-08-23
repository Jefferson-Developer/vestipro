import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/commercial_team.dart';
import '../bloc/team_form_bloc.dart';
import '../bloc/team_list_bloc.dart';
import '../bloc/team_list_event.dart';
import '../bloc/team_list_state.dart';
import 'team_form_page.dart';

class TeamListPage extends StatelessWidget {
  const TeamListPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.createFormBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final TeamListBloc Function() createBloc;
  final TeamFormBloc Function() createFormBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.teamManage,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<TeamListBloc>(
          create: (_) => createBloc()
            ..add(
              TeamListStarted(organizationId: organizationId, userId: userId),
            ),
          child: _TeamListView(
            organizationId: organizationId,
            userId: userId,
            createFormBloc: createFormBloc,
          ),
        );
      },
    );
  }
}

class _TeamListView extends StatelessWidget {
  const _TeamListView({
    required this.organizationId,
    required this.userId,
    required this.createFormBloc,
  });

  final String organizationId;
  final String userId;
  final TeamFormBloc Function() createFormBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<TeamListBloc, TeamListState>(
        listenWhen: (previous, current) =>
            previous.deleteStatus != current.deleteStatus,
        listener: (context, state) {
          if (state.deleteStatus == TeamListDeleteStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Equipe excluída.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.deleteStatus == TeamListDeleteStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.deleteFailure?.message ??
                  'Não foi possível excluir a equipe.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<TeamListBloc>();
          return AppAdminPageLayout(
            title: 'Equipes comerciais',
            actions: <Widget>[
              AppButton(
                label: 'Nova equipe',
                leadingIcon: Icons.group_add_outlined,
                onPressed: () => _openForm(context),
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por equipe, gestor ou membro',
                  onSearch: (query) => bloc.add(TeamListSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child:
                      state.loadStatus == TeamListLoadStatus.ready &&
                          state.teams.isEmpty
                      ? AppEmptyState(
                          icon: Icons.groups_outlined,
                          title: 'Nenhuma equipe comercial criada',
                          description:
                              'Crie a primeira equipe para organizar gestores, vendedores e assistentes.',
                          actionLabel: 'Criar primeira equipe',
                          onAction: () => _openForm(context),
                        )
                      : SingleChildScrollView(
                          child: AppDataTable<CommercialTeam>(
                            status: _tableStatus(state),
                            rows: state.filteredTeams,
                            rowIdBuilder: (team) => team.id,
                            emptyTitle: 'Nenhuma equipe encontrada',
                            emptyDescription:
                                'Ajuste a busca para localizar outra equipe.',
                            errorTitle: 'Não foi possível carregar as equipes',
                            errorMessage:
                                state.loadFailure?.message ??
                                'Tente novamente em breve.',
                            retryLabel: 'Tentar novamente',
                            onRetry: () =>
                                bloc.add(const TeamListRefreshRequested()),
                            mobileCardTitleBuilder: (context, team) =>
                                Text(team.name),
                            columns: <AppDataColumn<CommercialTeam>>[
                              AppDataColumn(
                                label: 'Equipe',
                                cellBuilder: (context, team) => Text(team.name),
                              ),
                              AppDataColumn(
                                label: 'Gestor',
                                cellBuilder: (context, team) =>
                                    Text(team.managerName),
                              ),
                              AppDataColumn(
                                label: 'Membros',
                                cellBuilder: (context, team) => Text(
                                  team.memberCount == 0
                                      ? '—'
                                      : '${team.memberCount}',
                                ),
                              ),
                              AppDataColumn(
                                label: 'Atualizada em',
                                cellBuilder: (context, team) =>
                                    Text(_dateLabel(team.team.updatedAt)),
                              ),
                            ],
                            rowActions: <AppDataTableAction<CommercialTeam>>[
                              AppDataTableAction<CommercialTeam>(
                                icon: Icons.edit_outlined,
                                semanticLabel: 'Editar equipe',
                                onPressed: (team) =>
                                    _openForm(context, team: team),
                              ),
                              AppDataTableAction<CommercialTeam>(
                                icon: Icons.delete_outline,
                                semanticLabel: 'Excluir equipe',
                                onPressed: (team) =>
                                    _confirmDelete(context, team),
                              ),
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

  AppDataTableStatus _tableStatus(TeamListState state) {
    return switch (state.loadStatus) {
      TeamListLoadStatus.loading => AppDataTableStatus.loading,
      TeamListLoadStatus.failure => AppDataTableStatus.error,
      TeamListLoadStatus.ready =>
        state.filteredTeams.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  Future<void> _openForm(BuildContext context, {CommercialTeam? team}) async {
    final saved = await TeamFormPage.showBottomSheet(
      context: context,
      organizationId: organizationId,
      userId: userId,
      createBloc: createFormBloc,
      initialTeam: team?.team,
    );
    if (saved != null && context.mounted) {
      context.read<TeamListBloc>().add(const TeamListRefreshRequested());
    }
  }

  Future<void> _confirmDelete(BuildContext context, CommercialTeam team) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Excluir equipe?',
      message:
          'A equipe só será excluída se não houver carteiras de clientes ou pedidos vinculados.',
      confirmLabel: 'Excluir',
    );
    if (confirmed && context.mounted) {
      context.read<TeamListBloc>().add(TeamListDeleteRequested(team));
    }
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
