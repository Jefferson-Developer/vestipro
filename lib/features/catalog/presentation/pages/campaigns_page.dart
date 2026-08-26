import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../../../products/presentation/bloc/product_search_bloc.dart';
import '../bloc/campaign_form_bloc.dart';
import '../bloc/campaign_list_bloc.dart';
import '../bloc/campaign_list_event.dart';
import '../bloc/campaign_list_state.dart';
import '../widgets/campaign_status_badge.dart';
import 'campaign_form_page.dart';

/// Administrative CRUD screen for `CatalogCampaign` (TASK-080): create,
/// edit and delete a lookbook/campaign. Gated by `Capability.catalogManage`
/// — the same capability `CollectionsPage`/`ProductFormPage` already
/// require — never available to `SALES_REP`/`SALES_ASSISTANT` without an
/// explicit grant.
class CampaignsPage extends StatelessWidget {
  const CampaignsPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.createFormBloc,
    required this.createProductSearchBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final CampaignListBloc Function() createBloc;
  final CampaignFormBloc Function() createFormBloc;
  final ProductSearchBloc Function() createProductSearchBloc;

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
        return BlocProvider<CampaignListBloc>(
          create: (_) => createBloc()
            ..add(
              CampaignListStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: _CampaignListView(
            organizationId: organizationId,
            userId: userId,
            permissionService: permissionService,
            createFormBloc: createFormBloc,
            createProductSearchBloc: createProductSearchBloc,
          ),
        );
      },
    );
  }
}

class _CampaignListView extends StatelessWidget {
  const _CampaignListView({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createFormBloc,
    required this.createProductSearchBloc,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final CampaignFormBloc Function() createFormBloc;
  final ProductSearchBloc Function() createProductSearchBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CampaignListBloc, CampaignListState>(
        listenWhen: (previous, current) =>
            previous.deleteStatus != current.deleteStatus,
        listener: (context, state) {
          if (state.deleteStatus == CampaignListDeleteStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Campanha excluída.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.deleteStatus == CampaignListDeleteStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.deleteFailure?.message ??
                  'Não foi possível excluir a campanha.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CampaignListBloc>();
          return AppAdminPageLayout(
            title: 'Campanhas e lookbooks',
            actions: <Widget>[
              AppButton(
                label: 'Nova campanha',
                leadingIcon: Icons.auto_awesome_outlined,
                onPressed: () => _openForm(context),
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por campanha',
                  onSearch: (query) =>
                      bloc.add(CampaignListSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child:
                      state.loadStatus == CampaignListLoadStatus.ready &&
                          state.campaigns.isEmpty
                      ? AppEmptyState(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Nenhuma campanha cadastrada',
                          description:
                              'Crie a primeira campanha para publicar um '
                              'lookbook editorial no catálogo.',
                          actionLabel: 'Criar primeira campanha',
                          onAction: () => _openForm(context),
                        )
                      : SingleChildScrollView(
                          child: AppDataTable<CatalogCampaign>(
                            status: _tableStatus(state),
                            rows: state.filteredCampaigns,
                            rowIdBuilder: (campaign) => campaign.id,
                            emptyTitle: 'Nenhuma campanha encontrada',
                            emptyDescription:
                                'Ajuste a busca para localizar outra campanha.',
                            errorTitle:
                                'Não foi possível carregar as campanhas',
                            errorMessage:
                                state.loadFailure?.message ??
                                'Tente novamente em breve.',
                            retryLabel: 'Tentar novamente',
                            onRetry: () =>
                                bloc.add(const CampaignListRefreshRequested()),
                            mobileCardTitleBuilder: (context, campaign) =>
                                Text(campaign.title),
                            columns: <AppDataColumn<CatalogCampaign>>[
                              AppDataColumn(
                                label: 'Campanha',
                                cellBuilder: (context, campaign) =>
                                    Text(campaign.title),
                              ),
                              AppDataColumn(
                                label: 'Status',
                                cellBuilder: (context, campaign) =>
                                    CampaignStatusBadge(
                                      status: campaign.statusAt(state.now),
                                    ),
                              ),
                              AppDataColumn(
                                label: 'Vigência',
                                cellBuilder: (context, campaign) =>
                                    Text(_vigenciaLabel(campaign)),
                              ),
                            ],
                            rowActions: <AppDataTableAction<CatalogCampaign>>[
                              AppDataTableAction<CatalogCampaign>(
                                icon: Icons.edit_outlined,
                                semanticLabel: 'Editar campanha',
                                onPressed: (campaign) =>
                                    _openForm(context, campaign: campaign),
                              ),
                              AppDataTableAction<CatalogCampaign>(
                                icon: Icons.delete_outline,
                                semanticLabel: 'Excluir campanha',
                                onPressed: (campaign) =>
                                    _confirmDelete(context, campaign),
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

  AppDataTableStatus _tableStatus(CampaignListState state) {
    return switch (state.loadStatus) {
      CampaignListLoadStatus.loading => AppDataTableStatus.loading,
      CampaignListLoadStatus.failure => AppDataTableStatus.error,
      CampaignListLoadStatus.ready =>
        state.filteredCampaigns.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  String _vigenciaLabel(CatalogCampaign campaign) {
    if (campaign.startAt == null && campaign.endAt == null) {
      return 'Sem período definido';
    }
    final start = campaign.startAt == null ? '—' : _date(campaign.startAt!);
    final end = campaign.endAt == null ? '—' : _date(campaign.endAt!);
    return '$start a $end';
  }

  String _date(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _openForm(
    BuildContext context, {
    CatalogCampaign? campaign,
  }) async {
    final saved = await CampaignFormPage.push(
      context: context,
      organizationId: organizationId,
      userId: userId,
      permissionService: permissionService,
      createBloc: createFormBloc,
      createProductSearchBloc: createProductSearchBloc,
      initialCampaign: campaign,
    );
    if (saved != null && context.mounted) {
      context.read<CampaignListBloc>().add(
        const CampaignListRefreshRequested(),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CatalogCampaign campaign,
  ) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Excluir campanha?',
      message:
          'A campanha "${campaign.title}" deixa de aparecer no catálogo e '
          'no lookbook imediatamente. Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
    );
    if (confirmed && context.mounted) {
      context.read<CampaignListBloc>().add(
        CampaignListDeleteRequested(campaign),
      );
    }
  }
}
