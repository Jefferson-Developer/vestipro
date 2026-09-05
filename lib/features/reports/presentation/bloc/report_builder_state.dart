import '../../../../core/errors/errors.dart';
import '../../domain/entities/report_catalog.dart';
import '../../domain/entities/report_definition.dart';
import '../../domain/entities/report_query_result.dart';

enum ReportBuilderStatus { initial, loading, ready, executing, failure }

final class ReportBuilderState {
  const ReportBuilderState({
    this.status = ReportBuilderStatus.initial,
    this.userId = '',
    this.definition,
    this.catalog,
    this.preview,
    this.validationMessage,
    this.failure,
  });

  final ReportBuilderStatus status;
  final String userId;
  final ReportDefinition? definition;
  final ReportCatalog? catalog;
  final ReportQueryResult? preview;
  final String? validationMessage;
  final Failure? failure;

  ReportBuilderState copyWith({
    ReportBuilderStatus? status,
    ReportDefinition? definition,
    ReportCatalog? catalog,
    ReportQueryResult? preview,
    bool clearPreview = false,
    String? validationMessage,
    bool clearValidation = false,
    Failure? failure,
    bool clearFailure = false,
  }) => ReportBuilderState(
    status: status ?? this.status,
    userId: userId,
    definition: definition ?? this.definition,
    catalog: catalog ?? this.catalog,
    preview: clearPreview ? null : preview ?? this.preview,
    validationMessage: clearValidation
        ? null
        : validationMessage ?? this.validationMessage,
    failure: clearFailure ? null : failure ?? this.failure,
  );
}
