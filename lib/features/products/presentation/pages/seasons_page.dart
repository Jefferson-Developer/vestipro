import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/season.dart';
import '../bloc/season_form_bloc.dart';
import '../bloc/season_list_bloc.dart';
import '../bloc/season_list_event.dart';
import '../bloc/season_list_state.dart';
import 'season_form_page.dart';

/// Administrative CRUD screen for `Season` (TASK-066): the fashion calendar
/// vocabulary ("Verão", "Inverno", ...) shared by every `Collection` of the
/// Organization. Gated by `Capability.catalogManage`, the same capability
/// `ProductFormPage`/`CollectionsPage` already require.
class SeasonsPage extends StatelessWidget {
  const SeasonsPage({
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
  final SeasonListBloc Function() createBloc;
  final SeasonFormBloc Function() createFormBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.catalogManage,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<SeasonListBloc>(
          create: (_) => createBloc()
            ..add(
              SeasonListStarted(organizationId: organizationId, userId: userId),
            ),
          child: _SeasonListView(
            organizationId: organizationId,
            userId: userId,
            createFormBloc: createFormBloc,
          ),
        );
      },
    );
  }
}

class _SeasonListView extends StatelessWidget {
  const _SeasonListView({
    required this.organizationId,
    required this.userId,
    required this.createFormBloc,
  });

  final String organizationId;
  final String userId;
  final SeasonFormBloc Function() createFormBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SeasonListBloc, SeasonListState>(
        listenWhen: (previous, current) =>
            previous.deleteStatus != current.deleteStatus,
        listener: (context, state) {
          if (state.deleteStatus == SeasonListDeleteStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Estação excluída.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.deleteStatus == SeasonListDeleteStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.deleteFailure?.message ??
                  'Não foi possível excluir a estação.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<SeasonListBloc>();
          return AppAdminPageLayout(
            title: 'Estações',
            actions: <Widget>[
              AppButton(
                label: 'Nova estação',
                leadingIcon: Icons.wb_sunny_outlined,
                onPressed: () => _openForm(context),
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por estação',
                  onSearch: (query) => bloc.add(SeasonListSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child:
                      state.loadStatus == SeasonListLoadStatus.ready &&
                          state.seasons.isEmpty
                      ? AppEmptyState(
                          icon: Icons.wb_sunny_outlined,
                          title: 'Nenhuma estação cadastrada',
                          description:
                              'Crie a primeira estação (ex.: Verão, Inverno) para organizar as '
                              'coleções da organização.',
                          actionLabel: 'Criar primeira estação',
                          onAction: () => _openForm(context),
                        )
                      : SingleChildScrollView(
                          child: AppDataTable<Season>(
                            status: _tableStatus(state),
                            rows: state.filteredSeasons,
                            rowIdBuilder: (season) => season.id,
                            emptyTitle: 'Nenhuma estação encontrada',
                            emptyDescription:
                                'Ajuste a busca para localizar outra estação.',
                            errorTitle: 'Não foi possível carregar as estações',
                            errorMessage:
                                state.loadFailure?.message ??
                                'Tente novamente em breve.',
                            retryLabel: 'Tentar novamente',
                            onRetry: () =>
                                bloc.add(const SeasonListRefreshRequested()),
                            mobileCardTitleBuilder: (context, season) =>
                                Text(season.name),
                            columns: <AppDataColumn<Season>>[
                              AppDataColumn(
                                label: 'Estação',
                                cellBuilder: (context, season) =>
                                    Text(season.name),
                              ),
                              AppDataColumn(
                                label: 'Atualizada em',
                                cellBuilder: (context, season) =>
                                    Text(_dateLabel(season.updatedAt)),
                              ),
                            ],
                            rowActions: <AppDataTableAction<Season>>[
                              AppDataTableAction<Season>(
                                icon: Icons.edit_outlined,
                                semanticLabel: 'Editar estação',
                                onPressed: (season) =>
                                    _openForm(context, season: season),
                              ),
                              AppDataTableAction<Season>(
                                icon: Icons.delete_outline,
                                semanticLabel: 'Excluir estação',
                                onPressed: (season) =>
                                    _confirmDelete(context, season),
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

  AppDataTableStatus _tableStatus(SeasonListState state) {
    return switch (state.loadStatus) {
      SeasonListLoadStatus.loading => AppDataTableStatus.loading,
      SeasonListLoadStatus.failure => AppDataTableStatus.error,
      SeasonListLoadStatus.ready =>
        state.filteredSeasons.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  Future<void> _openForm(BuildContext context, {Season? season}) async {
    final saved = await SeasonFormPage.showBottomSheet(
      context: context,
      organizationId: organizationId,
      userId: userId,
      createBloc: createFormBloc,
      initialSeason: season,
    );
    if (saved != null && context.mounted) {
      context.read<SeasonListBloc>().add(const SeasonListRefreshRequested());
    }
  }

  Future<void> _confirmDelete(BuildContext context, Season season) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Excluir estação?',
      message:
          'A estação só será excluída se não houver coleções vinculadas a ela.',
      confirmLabel: 'Excluir',
    );
    if (confirmed && context.mounted) {
      context.read<SeasonListBloc>().add(SeasonListDeleteRequested(season));
    }
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
