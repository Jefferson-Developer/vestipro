import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/category.dart';
import '../bloc/category_form_bloc.dart';
import '../bloc/category_list_bloc.dart';
import '../bloc/category_list_event.dart';
import '../bloc/category_list_state.dart';
import 'category_form_page.dart';

/// Administrative CRUD screen for the `Category` tree (TASK-067): the single
/// source of truth for "categoria"/"subcategoria" also reused by
/// `ProductFormPage`'s category picker and, later, by the catalog filters
/// (EPIC-10). Gated by `Capability.catalogManage`, the same capability
/// `ProductFormPage`/`SeasonsPage`/`CollectionsPage` already require.
///
/// Manual reordering among siblings is drag-and-drop on Web/desktop
/// (`ReorderableListView`) and an explicit "mover para cima/baixo" action on
/// mobile — never an accidental drag gesture competing with list scrolling.
/// Reparenting a category is always the separate, explicit action of
/// editing it and picking a different "categoria pai", never a side effect
/// of reordering.
class CategoriesPage extends StatelessWidget {
  const CategoriesPage({
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
  final CategoryListBloc Function() createBloc;
  final CategoryFormBloc Function() createFormBloc;

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
        return BlocProvider<CategoryListBloc>(
          create: (_) => createBloc()
            ..add(
              CategoryListStarted(
                organizationId: organizationId,
                userId: userId,
              ),
            ),
          child: _CategoryListView(
            organizationId: organizationId,
            userId: userId,
            createFormBloc: createFormBloc,
          ),
        );
      },
    );
  }
}

class _CategoryListView extends StatelessWidget {
  const _CategoryListView({
    required this.organizationId,
    required this.userId,
    required this.createFormBloc,
  });

  final String organizationId;
  final String userId;
  final CategoryFormBloc Function() createFormBloc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<CategoryListBloc, CategoryListState>(
        listenWhen: (previous, current) =>
            previous.deleteStatus != current.deleteStatus ||
            previous.reorderStatus != current.reorderStatus,
        listener: (context, state) {
          if (state.deleteStatus == CategoryListDeleteStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Categoria excluída.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.deleteStatus == CategoryListDeleteStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.deleteFailure?.message ??
                  'Não foi possível excluir a categoria.',
              variant: AppSnackbarVariant.error,
            );
          }
          if (state.reorderStatus == CategoryListReorderStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.reorderFailure?.message ??
                  'Não foi possível reordenar as categorias.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<CategoryListBloc>();
          return AppAdminPageLayout(
            title: 'Categorias',
            actions: <Widget>[
              AppButton(
                label: 'Nova categoria',
                leadingIcon: Icons.category_outlined,
                onPressed: () => _openForm(context),
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppSearchField(
                  hintText: 'Buscar por categoria ou subcategoria',
                  onSearch: (query) =>
                      bloc.add(CategoryListSearchChanged(query)),
                ),
                const SizedBox(height: AppSpacing.spacing16),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CategoryListState state) {
    if (state.loadStatus == CategoryListLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == CategoryListLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar as categorias',
        message: state.loadFailure?.message ?? 'Tente novamente em breve.',
        onRetry: () => context.read<CategoryListBloc>().add(
          const CategoryListRefreshRequested(),
        ),
        retryLabel: 'Tentar novamente',
      );
    }
    if (state.isSearching) {
      return _CategorySearchResults(
        results: state.searchResults,
        allCategories: state.categories,
        onEdit: (category) => _openForm(context, category: category),
        onDelete: (category) => _confirmDelete(context, category),
      );
    }
    if (state.rootCategories.isEmpty) {
      return AppEmptyState(
        icon: Icons.category_outlined,
        title: 'Nenhuma categoria cadastrada',
        description:
            'Crie a primeira categoria (ex.: Feminino, Masculino, Infantil) '
            'para organizar o catálogo da organização.',
        actionLabel: 'Criar primeira categoria',
        onAction: () => _openForm(context),
      );
    }
    return SingleChildScrollView(
      child: _CategorySiblingList(
        siblings: state.rootCategories,
        parentId: null,
        allCategories: state.categories,
        onAddChild: (parent) => _openForm(context, initialParentId: parent.id),
        onEdit: (category) => _openForm(context, category: category),
        onDelete: (category) => _confirmDelete(context, category),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context, {
    Category? category,
    String? initialParentId,
  }) async {
    final saved = await CategoryFormPage.showBottomSheet(
      context: context,
      organizationId: organizationId,
      userId: userId,
      createBloc: createFormBloc,
      initialCategory: category,
      initialParentId: initialParentId,
    );
    if (saved != null && context.mounted) {
      context.read<CategoryListBloc>().add(
        const CategoryListRefreshRequested(),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Category category) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Excluir categoria?',
      message:
          'A categoria só será excluída se não houver subcategorias ou '
          'produtos vinculados a ela.',
      confirmLabel: 'Excluir',
    );
    if (confirmed && context.mounted) {
      context.read<CategoryListBloc>().add(
        CategoryListDeleteRequested(category),
      );
    }
  }
}

/// One sibling group (either the root level or one category's direct
/// children), reorderable as a unit: drag handles on Web/desktop, explicit
/// "mover para cima/baixo" buttons on mobile. Never lets a drag move an item
/// out of this exact sibling group.
class _CategorySiblingList extends StatelessWidget {
  const _CategorySiblingList({
    required this.siblings,
    required this.parentId,
    required this.allCategories,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Category> siblings;
  final String? parentId;
  final List<Category> allCategories;
  final void Function(Category parent) onAddChild;
  final void Function(Category category) onEdit;
  final void Function(Category category) onDelete;

  List<Category> _childrenOf(String parentId) {
    return allCategories
        .where((category) => category.parentId == parentId)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Moves the sibling at [oldIndex] so it ends up at [newIndex] (already
  /// its final resting position — matching `ReorderableListView`'s
  /// `onReorderItem` semantics), then persists the resulting sibling order.
  void _reorder(BuildContext context, int oldIndex, int newIndex) {
    final reordered = List<Category>.of(siblings);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    context.read<CategoryListBloc>().add(
      CategoryListReorderRequested(
        parentId: parentId,
        orderedIds: reordered
            .map((category) => category.id)
            .toList(growable: false),
      ),
    );
  }

  void _moveBy(BuildContext context, int index, int offset) {
    final targetIndex = index + offset;
    if (targetIndex < 0 || targetIndex >= siblings.length) return;
    _reorder(context, index, targetIndex);
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        final canDrag = breakpoint != AppBreakpoint.mobile;
        if (canDrag) {
          return ReorderableListView.builder(
            key: ValueKey('category-reorderable-${parentId ?? 'root'}'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: siblings.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorder(context, oldIndex, newIndex),
            itemBuilder: (context, index) => _CategoryRow(
              key: ValueKey(siblings[index].id),
              category: siblings[index],
              children: _childrenOf(siblings[index].id),
              allCategories: allCategories,
              canDrag: true,
              onAddChild: onAddChild,
              onEdit: onEdit,
              onDelete: onDelete,
              onMoveUp: null,
              onMoveDown: null,
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var index = 0; index < siblings.length; index++)
              _CategoryRow(
                key: ValueKey(siblings[index].id),
                category: siblings[index],
                children: _childrenOf(siblings[index].id),
                allCategories: allCategories,
                canDrag: false,
                onAddChild: onAddChild,
                onEdit: onEdit,
                onDelete: onDelete,
                onMoveUp: index == 0 ? null : () => _moveBy(context, index, -1),
                onMoveDown: index == siblings.length - 1
                    ? null
                    : () => _moveBy(context, index, 1),
              ),
          ],
        );
      },
    );
  }
}

/// Actions collapsed into a mobile [_CategoryRow]'s overflow menu, so a
/// narrow row keeps only its two reorder buttons inline.
enum _CategoryRowAction { addChild, edit, delete }

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({
    required super.key,
    required this.category,
    required this.children,
    required this.allCategories,
    required this.canDrag,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final Category category;
  final List<Category> children;
  final List<Category> allCategories;
  final bool canDrag;
  final void Function(Category parent) onAddChild;
  final void Function(Category category) onEdit;
  final void Function(Category category) onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasChildren = widget.children.isNotEmpty;
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (widget.canDrag)
                const Padding(
                  padding: EdgeInsets.only(right: AppSpacing.spacing8),
                  child: Icon(Icons.drag_indicator, semanticLabel: 'Arrastar'),
                ),
              if (hasChildren)
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: _expanded
                      ? 'Recolher subcategorias'
                      : 'Expandir subcategorias',
                  onPressed: () => setState(() => _expanded = !_expanded),
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: Text(
                  widget.category.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (widget.canDrag) ...<Widget>[
                // Desktop/tablet has room for every action inline.
                IconButton(
                  icon: const Icon(Icons.add_outlined),
                  tooltip: 'Adicionar subcategoria',
                  onPressed: () => widget.onAddChild(widget.category),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar categoria',
                  onPressed: () => widget.onEdit(widget.category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Excluir categoria',
                  onPressed: () => widget.onDelete(widget.category),
                ),
              ] else ...<Widget>[
                // Mobile: only the explicit reorder actions stay inline —
                // add/edit/delete collapse into an overflow menu so the row
                // never overflows a narrow screen width.
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: 'Mover para cima',
                  onPressed: widget.onMoveUp,
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  tooltip: 'Mover para baixo',
                  onPressed: widget.onMoveDown,
                ),
                PopupMenuButton<_CategoryRowAction>(
                  tooltip: 'Mais ações',
                  onSelected: (action) => switch (action) {
                    _CategoryRowAction.addChild => widget.onAddChild(
                      widget.category,
                    ),
                    _CategoryRowAction.edit => widget.onEdit(widget.category),
                    _CategoryRowAction.delete => widget.onDelete(
                      widget.category,
                    ),
                  },
                  itemBuilder: (context) =>
                      const <PopupMenuEntry<_CategoryRowAction>>[
                        PopupMenuItem<_CategoryRowAction>(
                          value: _CategoryRowAction.addChild,
                          child: Text('Adicionar subcategoria'),
                        ),
                        PopupMenuItem<_CategoryRowAction>(
                          value: _CategoryRowAction.edit,
                          child: Text('Editar categoria'),
                        ),
                        PopupMenuItem<_CategoryRowAction>(
                          value: _CategoryRowAction.delete,
                          child: Text('Excluir categoria'),
                        ),
                      ],
                ),
              ],
            ],
          ),
          if (_expanded && hasChildren)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.spacing32),
              child: _CategorySiblingList(
                siblings: widget.children,
                parentId: widget.category.id,
                allCategories: widget.allCategories,
                onAddChild: widget.onAddChild,
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
              ),
            ),
        ],
      ),
    );
  }
}

class _CategorySearchResults extends StatelessWidget {
  const _CategorySearchResults({
    required this.results,
    required this.allCategories,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Category> results;
  final List<Category> allCategories;
  final void Function(Category category) onEdit;
  final void Function(Category category) onDelete;

  String? _parentName(Category category) {
    final parentId = category.parentId;
    if (parentId == null) return null;
    for (final candidate in allCategories) {
      if (candidate.id == parentId) return candidate.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const AppEmptyState(
        icon: Icons.search_off_outlined,
        title: 'Nenhuma categoria encontrada',
        description: 'Ajuste a busca para localizar outra categoria.',
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final category = results[index];
        final parentName = _parentName(category);
        return _SurfaceCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (parentName != null)
                      Text(
                        'Subcategoria de: $parentName',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar categoria',
                onPressed: () => onEdit(category),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Excluir categoria',
                onPressed: () => onDelete(category),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Minimal bordered surface container reused by [_CategoryRow] and
/// [_CategorySearchResults] — the same `Container`-with-`colors.surface`
/// styling `AppKpiCard` already applies, kept local since no shared
/// generic "card" primitive exists in the Design System yet.
class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }
}
