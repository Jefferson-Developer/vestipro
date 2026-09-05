import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/report_catalog.dart';
import '../entities/report_definition.dart';

@injectable
final class ValidateReportDefinition {
  const ValidateReportDefinition();

  AppResult<void> call(ReportDefinition definition, ReportCatalog catalog) {
    if (definition.organizationId.trim().isEmpty ||
        definition.companyId.trim().isEmpty) {
      return const AppFailure<void>(
        ValidationFailure('Organização e empresa são obrigatórias.'),
      );
    }
    if (definition.dimensions.isEmpty) {
      return const AppFailure<void>(
        ValidationFailure('Escolha ao menos uma dimensão.'),
      );
    }
    if (definition.metrics.isEmpty) {
      return const AppFailure<void>(
        ValidationFailure('Escolha ao menos uma métrica.'),
      );
    }
    final periodFilters = definition.filters.where(
      (filter) => filter.fieldId == 'period',
    );
    if (periodFilters.isEmpty ||
        !RegExp(
          r'^\d{4}-(0[1-9]|1[0-2])$',
        ).hasMatch(periodFilters.first.value)) {
      return const AppFailure<void>(
        ValidationFailure('Informe o período no formato AAAA-MM.'),
      );
    }
    if (definition.dimensions.length > catalog.maxDimensions ||
        definition.metrics.length > catalog.maxMetrics) {
      return const AppFailure<void>(
        ValidationFailure(
          'A consulta excede o limite de dimensões ou métricas.',
        ),
      );
    }
    final dimensionFamilies = definition.dimensions
        .map(
          (id) =>
              const <String>{'product', 'category', 'collection'}.contains(id)
              ? 'product'
              : id,
        )
        .toSet();
    if (dimensionFamilies.length > 1) {
      return const AppFailure<void>(
        ValidationFailure(
          'As dimensões escolhidas não podem ser combinadas na mesma consulta.',
        ),
      );
    }
    for (final id in <String>[
      ...definition.dimensions,
      ...definition.metrics,
    ]) {
      final field = catalog.find(id);
      if (field == null || !field.isAvailable) {
        return AppFailure<void>(
          ValidationFailure(
            'O campo "$id" não está disponível para seu perfil.',
          ),
        );
      }
    }
    for (final metricId in definition.metrics) {
      final metric = catalog.find(metricId)!;
      final incompatible = definition.dimensions.where(
        (dimension) =>
            metric.compatibleDimensions.isNotEmpty &&
            !metric.compatibleDimensions.contains(dimension),
      );
      if (incompatible.isNotEmpty) {
        return AppFailure<void>(
          ValidationFailure(
            '${metric.label} não pode ser combinada com ${catalog.find(incompatible.first)?.label ?? incompatible.first}.',
          ),
        );
      }
    }
    return const AppSuccess<void>(null);
  }
}
