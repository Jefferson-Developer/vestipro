import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/collection.dart';
import '../../domain/value_objects/collection_status.dart';
import '../bloc/collection_form_bloc.dart';
import '../bloc/collection_list_bloc.dart';
import '../bloc/collection_list_event.dart';
import '../bloc/collection_list_state.dart';
import 'collection_form_page.dart';

/// Administrative CRUD screen for `Collection` (TASK-066): create/edit and
/// close a fashion calendar Collection. Gated by `Capability.catalogManage`,
/// the same capability `ProductFormPage` already requires.
class CollectionsPage extends StatelessWidget {
  const CollectionsPage({
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
  final CollectionListBloc Function() createBloc;
  final CollectionFormBloc Function() createFormBloc;

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
        return BlocProvider<CollectionListBloc>(
          create: (_) => createBloc()
            ..add(
              CollectionListStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: _CollectionListView(
            organizationId: organizationId,
            userId: userId,
            createFormBloc: createFormBloc,
          ),
        );
      },
    );
  }
}

class _CollectionListView extends StatelessWidget {
  const _CollectionListView({
    required this.organizationId,
    required this.userId,
    required this.createFormBloc,
  });

  final String organizationId;
  final String userId;
  final CollectionFormBloc Function() createFormBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CollectionListBloc, CollectionListState>(
        listenWhen: (previous, current) =>
            previous.closeStatus != current.closeStatus,
        listener: (context, state) {
          if (state.closeStatus == CollectionListCloseStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Coleção encerrada.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.closeStatus == CollectionListCloseStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.closeFailure?.message ??
                  'Não foi possível encerrar a coleção.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CollectionListBloc>();
          return AppAdminPageLayout(
            title: 'Coleções',
            actions: <Widget>[
              AppButton(
                label: 'Nova coleção',
                leadingIcon: Icons.style_outlined,
                onPressed: () => _openForm(context),
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por coleção',
                  onSearch: (query) =>
                      bloc.add(CollectionListSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(
                  child:
                      state.loadStatus == CollectionListLoadStatus.ready &&
                          state.collections.isEmpty
                      ? AppEmptyState(
                          icon: Icons.style_outlined,
                          title: 'Nenhuma coleção cadastrada',
                          description:
                              'Crie a primeira coleção (ex.: "Verão 2026") para organizar os '
                              'produtos por calendário de moda.',
                          actionLabel: 'Criar primeira coleção',
                          onAction: () => _openForm(context),
                        )
                      : SingleChildScrollView(
                          child: AppDataTable<Collection>(
                            status: _tableStatus(state),
                            rows: state.filteredCollections,
                            rowIdBuilder: (collection) => collection.id,
                            emptyTitle: 'Nenhuma coleção encontrada',
                            emptyDescription:
                                'Ajuste a busca para localizar outra coleção.',
                            errorTitle: 'Não foi possível carregar as coleções',
                            errorMessage:
                                state.loadFailure?.message ??
                                'Tente novamente em breve.',
                            retryLabel: 'Tentar novamente',
                            onRetry: () => bloc.add(
                              const CollectionListRefreshRequested(),
                            ),
                            mobileCardTitleBuilder: (context, collection) =>
                                Text(collection.name),
                            columns: <AppDataColumn<Collection>>[
                              AppDataColumn(
                                label: 'Coleção',
                                cellBuilder: (context, collection) =>
                                    Text(collection.name),
                              ),
                              AppDataColumn(
                                label: 'Ano',
                                cellBuilder: (context, collection) =>
                                    Text(collection.year?.toString() ?? '—'),
                              ),
                              AppDataColumn(
                                label: 'Status',
                                cellBuilder: (context, collection) => Text(
                                  collection.status == CollectionStatus.active
                                      ? 'Ativa'
                                      : 'Encerrada',
                                ),
                              ),
                            ],
                            rowActions: <AppDataTableAction<Collection>>[
                              AppDataTableAction<Collection>(
                                icon: Icons.edit_outlined,
                                semanticLabel: 'Editar coleção',
                                onPressed: (collection) =>
                                    _openForm(context, collection: collection),
                              ),
                              AppDataTableAction<Collection>(
                                icon: Icons.lock_outline,
                                semanticLabel: 'Encerrar coleção',
                                onPressed: (collection) =>
                                    _confirmClose(context, collection),
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

  AppDataTableStatus _tableStatus(CollectionListState state) {
    return switch (state.loadStatus) {
      CollectionListLoadStatus.loading => AppDataTableStatus.loading,
      CollectionListLoadStatus.failure => AppDataTableStatus.error,
      CollectionListLoadStatus.ready =>
        state.filteredCollections.isEmpty
            ? AppDataTableStatus.empty
            : AppDataTableStatus.idle,
    };
  }

  Future<void> _openForm(BuildContext context, {Collection? collection}) async {
    final saved = await CollectionFormPage.showBottomSheet(
      context: context,
      organizationId: organizationId,
      userId: userId,
      createBloc: createFormBloc,
      initialCollection: collection,
    );
    if (saved != null && context.mounted) {
      context.read<CollectionListBloc>().add(
        const CollectionListRefreshRequested(),
      );
    }
  }

  Future<void> _confirmClose(
    BuildContext context,
    Collection collection,
  ) async {
    if (collection.status == CollectionStatus.closed) return;
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Encerrar coleção?',
      message:
          'Os produtos já associados a esta coleção continuam disponíveis; '
          'a coleção só deixa de aceitar novas associações e passa a ser '
          'sinalizada como encerrada nos filtros de catálogo.',
      confirmLabel: 'Encerrar',
    );
    if (confirmed && context.mounted) {
      context.read<CollectionListBloc>().add(
        CollectionListCloseRequested(collection),
      );
    }
  }
}
