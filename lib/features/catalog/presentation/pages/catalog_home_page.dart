import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/catalog_home_item.dart';
import '../../domain/entities/catalog_home_section_type.dart';
import '../bloc/catalog_home_bloc.dart';
import '../bloc/catalog_home_event.dart';
import '../bloc/catalog_home_state.dart';
import '../widgets/catalog_home_section_view.dart';

/// The catalog's entry screen (TASK-076, EPIC-10): coleções em destaque,
/// lançamentos e campanhas in a premium, responsive vitrine — the
/// representative's and the client's starting point to browse the catalog.
///
/// Layout: mobile shows one section per row (each a horizontal carousel);
/// tablet/desktop lay two sections side by side per row instead of just
/// stretching the mobile layout, per TASK-076's own responsiveness
/// requirement.
class CatalogHomePage extends StatelessWidget {
  const CatalogHomePage({
    required this.organizationId,
    required this.userId,
    required this.createBloc,
    this.companyId,
    this.onCreateProductTap,
    this.onSectionItemTap,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final CatalogHomeBloc Function() createBloc;
  final VoidCallback? onCreateProductTap;

  /// Called when the viewer taps a section item — routing to the
  /// product/collection/campaign detail is decided by whoever instantiates
  /// this page, never by the page itself (TASK-078/TASK-080 are not built
  /// yet).
  final void Function(CatalogHomeSectionType type, CatalogHomeItem item)?
  onSectionItemTap;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogHomeBloc>(
      create: (_) => createBloc()
        ..add(
          CatalogHomeStarted(
            organizationId: organizationId,
            companyId: companyId,
            userId: userId,
          ),
        ),
      child: _CatalogHomeView(
        onCreateProductTap: onCreateProductTap,
        onSectionItemTap: onSectionItemTap,
      ),
    );
  }
}

class _CatalogHomeView extends StatelessWidget {
  const _CatalogHomeView({this.onCreateProductTap, this.onSectionItemTap});

  final VoidCallback? onCreateProductTap;
  final void Function(CatalogHomeSectionType type, CatalogHomeItem item)?
  onSectionItemTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CatalogHomeBloc, CatalogHomeState>(
          builder: (context, state) {
            final bloc = context.read<CatalogHomeBloc>();

            if (state.isInitialLoading) {
              return const _CatalogHomeSkeleton();
            }

            if (state.status == CatalogHomeLoadStatus.failure) {
              return AppErrorState(
                title: 'Não foi possível carregar o catálogo',
                message: state.failure?.message ?? 'Tente novamente em breve.',
                retryLabel: 'Tentar novamente',
                onRetry: () => bloc.add(const CatalogHomeRefreshRequested()),
              );
            }

            if (state.sections.isEmpty) {
              return AppEmptyState(
                icon: Icons.storefront_outlined,
                title: 'Catálogo em preparação',
                description:
                    'Assim que houver coleções, lançamentos ou campanhas '
                    'ativas, eles aparecem aqui.',
                actionLabel: onCreateProductTap == null ? null : 'Novo produto',
                onAction: onCreateProductTap,
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                bloc.add(const CatalogHomeRefreshRequested());
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final breakpoint = AppBreakpoints.resolve(
                    constraints.maxWidth,
                  );
                  final columns = switch (breakpoint) {
                    AppBreakpoint.mobile => 1,
                    AppBreakpoint.tablet => 1,
                    AppBreakpoint.desktop => 2,
                    AppBreakpoint.largeDesktop => 2,
                  };

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (state.isStale) ...<Widget>[
                          const _StaleDataNotice(),
                          const SizedBox(height: AppSpacing.spacing16),
                        ],
                        _SectionWrap(
                          columns: columns,
                          children: state.sections
                              .map(
                                (section) => Semantics(
                                  container: true,
                                  label: section.title,
                                  child: CatalogHomeSectionView(
                                    section: section,
                                    onItemTap: (item) {
                                      bloc.add(
                                        CatalogHomeSectionOpened(section.type),
                                      );
                                      onSectionItemTap?.call(
                                        section.type,
                                        item,
                                      );
                                    },
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Lays out each section full-width on mobile/tablet, or two side by side on
/// desktop — the "aproveita o espaço extra sem apenas esticar o mobile"
/// requirement, without a bespoke grid: each section keeps its own
/// intrinsic height (its carousel), so a simple [Wrap] is enough.
class _SectionWrap extends StatelessWidget {
  const _SectionWrap({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final child in children) ...<Widget>[
            child,
            const SizedBox(height: AppSpacing.spacing24),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - AppSpacing.spacing24 * (columns - 1)) /
            columns;
        return Wrap(
          spacing: AppSpacing.spacing24,
          runSpacing: AppSpacing.spacing24,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

class _CatalogHomeSkeleton extends StatelessWidget {
  const _CatalogHomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < 2; i++) ...<Widget>[
            const AppSkeleton.line(width: AppSpacing.spacing64),
            const SizedBox(height: AppSpacing.spacing12),
            AppProductCarousel(
              products: const <AppProductCardData>[],
              isLoading: true,
              onProductTap: (_) {},
            ),
            const SizedBox(height: AppSpacing.spacing24),
          ],
        ],
      ),
    );
  }
}

class _StaleDataNotice extends StatelessWidget {
  const _StaleDataNotice();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing12),
        child: Row(
          children: <Widget>[
            Icon(Icons.sync_problem_outlined, color: colors.warning),
            const SizedBox(width: AppSpacing.spacing8),
            Expanded(
              child: Text(
                'Mostrando o último catálogo carregado: pode estar '
                'desatualizado.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
