import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/customer_portfolio_filters.dart';
import '../../domain/entities/customer_segment_criteria.dart';
import '../../domain/value_objects/customer_segment_visibility.dart';
import '../bloc/customer_portfolio_bloc.dart';
import '../bloc/customer_portfolio_event.dart';
import '../bloc/customer_segment_bloc.dart';
import '../bloc/customer_segment_event.dart';
import '../bloc/customer_segment_state.dart';

/// Saved-segment quick filters for the carteira (TASK-053): lets the user
/// apply a previously saved segment with one tap, and save the carteira's
/// current filters (plus a purchased-category criterion) as a new segment.
///
/// Requires a [CustomerSegmentBloc] and a [CustomerPortfolioBloc] above it in
/// the widget tree. `CustomerPortfolioPage` only mounts this widget when a
/// segment bloc builder was actually provided, so existing carteira call
/// sites keep working unchanged if they do not opt in.
class CustomerSegmentQuickFilters extends StatelessWidget {
  const CustomerSegmentQuickFilters({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final segmentState = context.watch<CustomerSegmentBloc>().state;
    final portfolioFilters = context
        .watch<CustomerPortfolioBloc>()
        .state
        .filters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Segmentos salvos',
          style: AppTypography.titleMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing8),
        if (segmentState.listStatus == CustomerSegmentListStatus.failure)
          Text(
            segmentState.listFailure?.message ??
                'Nao foi possivel carregar os segmentos.',
            style: AppTypography.bodySmall.copyWith(color: colors.error),
          )
        else
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: <Widget>[
              for (final segment in segmentState.segments)
                AppFilterChip(
                  label: segment.name,
                  leadingIcon: segment.isShared
                      ? Icons.groups_outlined
                      : Icons.lock_outline,
                  selected:
                      !portfolioFilters.isEmpty &&
                      portfolioFilters == segment.criteria.toPortfolioFilters(),
                  onSelected: (_) => context.read<CustomerPortfolioBloc>().add(
                    CustomerPortfolioFiltersChanged(
                      segment.criteria.toPortfolioFilters(),
                    ),
                  ),
                  onRemove: segment.isEditableBy(userId)
                      ? () => context.read<CustomerSegmentBloc>().add(
                          CustomerSegmentDeleteRequested(segment),
                        )
                      : null,
                ),
              AppFilterChip(
                label: 'Novo segmento',
                leadingIcon: Icons.add,
                onSelected: (_) => _openSaveDialog(
                  context,
                  segmentBloc: context.read<CustomerSegmentBloc>(),
                  currentFilters: portfolioFilters,
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.spacing16),
      ],
    );
  }

  Future<void> _openSaveDialog(
    BuildContext context, {
    required CustomerSegmentBloc segmentBloc,
    required CustomerPortfolioFilters currentFilters,
  }) {
    return AppModal.show<void>(
      context: context,
      title: 'Salvar segmento',
      body: BlocProvider<CustomerSegmentBloc>.value(
        value: segmentBloc,
        child: _SaveSegmentForm(currentFilters: currentFilters),
      ),
    );
  }
}

class _SaveSegmentForm extends StatefulWidget {
  const _SaveSegmentForm({required this.currentFilters});

  final CustomerPortfolioFilters currentFilters;

  @override
  State<_SaveSegmentForm> createState() => _SaveSegmentFormState();
}

class _SaveSegmentFormState extends State<_SaveSegmentForm> {
  final _nameController = TextEditingController();
  final _categoriesController = TextEditingController();
  CustomerSegmentVisibility _visibility = CustomerSegmentVisibility.private;
  String _name = '';

  CustomerSegmentCriteria get _criteria => CustomerSegmentCriteria(
    portfolioFilters: widget.currentFilters,
    purchasedCategoryCodes: _csvSet(_categoriesController.text),
  ).normalized();

  @override
  void initState() {
    super.initState();
    context.read<CustomerSegmentBloc>().add(
      CustomerSegmentPreviewRequested(_criteria),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return BlocListener<CustomerSegmentBloc, CustomerSegmentState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus &&
          current.saveStatus == CustomerSegmentSaveStatus.success,
      listener: (context, state) => Navigator.of(context).pop(),
      child: BlocBuilder<CustomerSegmentBloc, CustomerSegmentState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                controller: _nameController,
                label: 'Nome do segmento',
                hintText: 'Ex.: Clientes SP alto potencial',
                semanticLabel: 'Nome do segmento',
                errorText: state.fieldErrors['name'],
                onChanged: (value) => setState(() => _name = value),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppTextField(
                controller: _categoriesController,
                label: 'Categorias compradas (opcional)',
                hintText: 'Ex.: inverno, praia',
                semanticLabel: 'Categorias de produto compradas',
                onChanged: (_) => context.read<CustomerSegmentBloc>().add(
                  CustomerSegmentPreviewRequested(_criteria),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Wrap(
                spacing: AppSpacing.spacing8,
                children: <Widget>[
                  AppFilterChip(
                    label: 'Privado',
                    leadingIcon: Icons.lock_outline,
                    selected: _visibility == CustomerSegmentVisibility.private,
                    onSelected: (_) => setState(
                      () => _visibility = CustomerSegmentVisibility.private,
                    ),
                  ),
                  AppFilterChip(
                    label: 'Compartilhado',
                    leadingIcon: Icons.groups_outlined,
                    selected: _visibility == CustomerSegmentVisibility.shared,
                    onSelected: (_) => setState(
                      () => _visibility = CustomerSegmentVisibility.shared,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.spacing16),
              Text(
                _previewLabel(state),
                style: AppTypography.bodySmall.copyWith(color: colors.outline),
              ),
              if (state.saveStatus ==
                  CustomerSegmentSaveStatus.failure) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  state.saveFailure?.message ??
                      'Nao foi possivel salvar o segmento.',
                  style: AppTypography.bodySmall.copyWith(color: colors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.spacing24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.spacing12,
                children: <Widget>[
                  AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  AppButton(
                    label: 'Salvar segmento',
                    isLoading:
                        state.saveStatus == CustomerSegmentSaveStatus.saving,
                    isDisabled: _name.trim().isEmpty,
                    onPressed: () => context.read<CustomerSegmentBloc>().add(
                      CustomerSegmentSaveRequested(
                        name: _nameController.text,
                        visibility: _visibility,
                        criteria: _criteria,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _previewLabel(CustomerSegmentState state) {
    return switch (state.previewStatus) {
      CustomerSegmentPreviewStatus.idle => '',
      CustomerSegmentPreviewStatus.loading => 'Calculando clientes...',
      CustomerSegmentPreviewStatus.ready =>
        state.preview!.isAtLeastCount
            ? '${state.preview!.matchedCount}+ clientes correspondem a este segmento'
            : '${state.preview!.matchedCount} clientes correspondem a este segmento',
      CustomerSegmentPreviewStatus.failure =>
        'Nao foi possivel calcular a contagem de clientes.',
    };
  }

  Set<String> _csvSet(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
}
