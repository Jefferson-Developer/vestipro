import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/repositories/report_repository.dart';
import '../../domain/usecases/report_use_cases.dart';
import '../../domain/usecases/validate_report_definition.dart';
import 'report_builder_event.dart';
import 'report_builder_state.dart';

@injectable
final class ReportBuilderBloc
    extends Bloc<ReportBuilderEvent, ReportBuilderState> {
  ReportBuilderBloc(
    this._loadCatalog,
    this._execute,
    this._validate,
    this._drafts,
    this._analytics,
  ) : super(const ReportBuilderState()) {
    on<ReportBuilderStarted>(_onStarted);
    on<ReportDimensionToggled>(_onDimensionToggled);
    on<ReportMetricToggled>(_onMetricToggled);
    on<ReportFilterChanged>(_onFilterChanged);
    on<ReportComparisonChanged>(_onComparisonChanged);
    on<ReportSortChanged>(_onSortChanged);
    on<ReportExecutionRequested>(_onExecute);
    on<ReportBuilderRetried>(_onRetry);
  }

  final LoadReportCatalog _loadCatalog;
  final ExecuteReportQuery _execute;
  final ValidateReportDefinition _validate;
  final ReportDraftRepository _drafts;
  final AnalyticsService _analytics;

  Future<void> _onStarted(
    ReportBuilderStarted event,
    Emitter<ReportBuilderState> emit,
  ) async {
    emit(
      ReportBuilderState(
        status: ReportBuilderStatus.loading,
        userId: event.userId,
      ),
    );
    final result = await _loadCatalog(
      organizationId: event.organizationId,
      companyId: event.companyId,
    );
    switch (result) {
      case AppFailure(failure: final failure):
        emit(
          ReportBuilderState(
            status: ReportBuilderStatus.failure,
            userId: event.userId,
            failure: failure,
          ),
        );
      case AppSuccess(value: final catalog):
        final draft = await _drafts.load(
          userId: event.userId,
          organizationId: event.organizationId,
          companyId: event.companyId,
        );
        var definition =
            draft ??
            ReportDefinition(
              organizationId: event.organizationId,
              companyId: event.companyId,
            );
        if (!definition.filters.any((filter) => filter.fieldId == 'period')) {
          final now = DateTime.now();
          definition = definition.copyWith(
            filters: <ReportFilter>[
              ...definition.filters,
              ReportFilter(
                fieldId: 'period',
                operatorId: 'equals',
                value:
                    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}',
              ),
            ],
          );
        }
        emit(
          ReportBuilderState(
            status: ReportBuilderStatus.ready,
            userId: event.userId,
            catalog: catalog,
            definition: _sanitize(definition, catalog),
          ),
        );
    }
  }

  Future<void> _onRetry(
    ReportBuilderRetried event,
    Emitter<ReportBuilderState> emit,
  ) async {
    final definition = state.definition;
    if (definition == null) return;
    add(
      ReportBuilderStarted(
        organizationId: definition.organizationId,
        companyId: definition.companyId,
        userId: state.userId,
      ),
    );
  }

  Future<void> _onDimensionToggled(
    ReportDimensionToggled event,
    Emitter<ReportBuilderState> emit,
  ) async {
    final definition = state.definition;
    final catalog = state.catalog;
    if (definition == null ||
        catalog == null ||
        catalog.find(event.id) == null) {
      return;
    }
    final dimensions = [...definition.dimensions];
    if (dimensions.remove(event.id)) {
      // removed
    } else if (dimensions.length < catalog.maxDimensions) {
      dimensions.add(event.id);
    }
    final metrics = definition.metrics
        .where((id) {
          final metric = catalog.find(id);
          return metric != null &&
              dimensions.every(
                (dimension) =>
                    metric.compatibleDimensions.isEmpty ||
                    metric.compatibleDimensions.contains(dimension),
              );
        })
        .toList(growable: false);
    await _update(
      emit,
      definition.copyWith(
        dimensions: dimensions,
        groupBy: dimensions,
        metrics: metrics,
      ),
    );
  }

  Future<void> _onMetricToggled(
    ReportMetricToggled event,
    Emitter<ReportBuilderState> emit,
  ) async {
    final definition = state.definition;
    final catalog = state.catalog;
    final metric = catalog?.find(event.id);
    if (definition == null ||
        catalog == null ||
        metric == null ||
        !metric.isAvailable) {
      return;
    }
    final compatible = definition.dimensions.every(
      (id) =>
          metric.compatibleDimensions.isEmpty ||
          metric.compatibleDimensions.contains(id),
    );
    if (!compatible) {
      emit(
        state.copyWith(
          validationMessage:
              '${metric.label} não é compatível com as dimensões escolhidas.',
        ),
      );
      return;
    }
    final metrics = [...definition.metrics];
    if (metrics.remove(event.id)) {
      // removed
    } else if (metrics.length < catalog.maxMetrics) {
      metrics.add(event.id);
    }
    await _update(emit, definition.copyWith(metrics: metrics));
  }

  Future<void> _onFilterChanged(
    ReportFilterChanged event,
    Emitter<ReportBuilderState> emit,
  ) async {
    final definition = state.definition;
    if (definition == null) return;
    final filters =
        definition.filters
            .where((item) => item.fieldId != event.filter.fieldId)
            .toList()
          ..add(event.filter);
    await _update(emit, definition.copyWith(filters: filters));
  }

  Future<void> _onComparisonChanged(
    ReportComparisonChanged event,
    Emitter<ReportBuilderState> emit,
  ) => state.definition == null
      ? Future<void>.value()
      : _update(
          emit,
          state.definition!.copyWith(comparisonPeriod: event.value),
        );

  Future<void> _onSortChanged(
    ReportSortChanged event,
    Emitter<ReportBuilderState> emit,
  ) => state.definition == null
      ? Future<void>.value()
      : _update(
          emit,
          state.definition!.copyWith(
            sortBy: event.value,
            clearSort: event.value == null,
          ),
        );

  Future<void> _update(
    Emitter<ReportBuilderState> emit,
    ReportDefinition definition,
  ) async {
    final validation = state.catalog == null
        ? null
        : _validate(definition, state.catalog!);
    final message = validation is AppFailure<void>
        ? validation.failure.message
        : null;
    emit(
      state.copyWith(
        status: ReportBuilderStatus.ready,
        definition: definition,
        clearPreview: true,
        validationMessage: message,
        clearValidation: message == null,
        clearFailure: true,
      ),
    );
    await _drafts.save(userId: state.userId, definition: definition);
  }

  Future<void> _onExecute(
    ReportExecutionRequested event,
    Emitter<ReportBuilderState> emit,
  ) async {
    final definition = state.definition;
    final catalog = state.catalog;
    if (definition == null || catalog == null) return;
    final validation = _validate(definition, catalog);
    if (validation case AppFailure<void>(failure: final failure)) {
      emit(state.copyWith(validationMessage: failure.message));
      return;
    }
    emit(
      state.copyWith(
        status: ReportBuilderStatus.executing,
        clearValidation: true,
        clearFailure: true,
      ),
    );
    await _analytics.logEvent(
      AnalyticsEvents.reportBuilt,
      parameters: <String, Object?>{
        'dimension_count': definition.dimensions.length,
        'metric_count': definition.metrics.length,
      },
    );
    final result = await _execute(definition, catalog);
    switch (result) {
      case AppSuccess(value: final preview):
        emit(
          state.copyWith(status: ReportBuilderStatus.ready, preview: preview),
        );
        await _analytics.logEvent(
          AnalyticsEvents.reportQueryExecuted,
          parameters: <String, Object?>{'row_count': preview.rows.length},
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(status: ReportBuilderStatus.ready, failure: failure),
        );
    }
  }

  ReportDefinition _sanitize(
    ReportDefinition definition,
    ReportCatalog catalog,
  ) {
    final dimensions = definition.dimensions
        .where((id) => catalog.find(id)?.isAvailable == true)
        .toList(growable: false);
    final metrics = definition.metrics
        .where((id) {
          final field = catalog.find(id);
          return field != null &&
              field.isAvailable &&
              dimensions.every(
                (dimension) =>
                    field.compatibleDimensions.isEmpty ||
                    field.compatibleDimensions.contains(dimension),
              );
        })
        .toList(growable: false);
    return definition.copyWith(
      dimensions: dimensions,
      groupBy: dimensions,
      metrics: metrics,
    );
  }
}
