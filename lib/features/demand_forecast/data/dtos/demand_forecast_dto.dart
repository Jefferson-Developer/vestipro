import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class DemandForecastHistoryPointDto {
  const DemandForecastHistoryPointDto({
    required this.periodKey,
    required this.quantity,
    required this.observed,
  });

  factory DemandForecastHistoryPointDto.fromJson(Map<String, dynamic> json) {
    final periodKey = json['periodKey'];
    final quantity = json['quantity'];
    final observed = json['observed'];
    if (periodKey is! String || quantity is! num || observed is! bool) {
      throw const ValidationException(
        'Invalid demand forecast history point payload.',
        code: 'invalid_demand_forecast_history_point_payload',
      );
    }
    return DemandForecastHistoryPointDto(
      periodKey: periodKey,
      quantity: quantity.toDouble(),
      observed: observed,
    );
  }

  final String periodKey;
  final double quantity;
  final bool observed;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'periodKey': periodKey,
      'quantity': quantity,
      'observed': observed,
    };
  }
}

final class DemandForecastPeriodProjectionDto {
  const DemandForecastPeriodProjectionDto({
    required this.periodKey,
    required this.predictedQuantity,
    required this.lowerBound,
    required this.upperBound,
    this.actualQuantity,
    this.absolutePercentageError,
  });

  factory DemandForecastPeriodProjectionDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final periodKey = json['periodKey'];
    final predictedQuantity = json['predictedQuantity'];
    final lowerBound = json['lowerBound'];
    final upperBound = json['upperBound'];
    final actualQuantity = json['actualQuantity'];
    final absolutePercentageError = json['absolutePercentageError'];
    if (periodKey is! String ||
        predictedQuantity is! num ||
        lowerBound is! num ||
        upperBound is! num ||
        (actualQuantity != null && actualQuantity is! num) ||
        (absolutePercentageError != null && absolutePercentageError is! num)) {
      throw const ValidationException(
        'Invalid demand forecast period projection payload.',
        code: 'invalid_demand_forecast_period_projection_payload',
      );
    }
    return DemandForecastPeriodProjectionDto(
      periodKey: periodKey,
      predictedQuantity: predictedQuantity.toDouble(),
      lowerBound: lowerBound.toDouble(),
      upperBound: upperBound.toDouble(),
      actualQuantity: (actualQuantity as num?)?.toDouble(),
      absolutePercentageError: (absolutePercentageError as num?)?.toDouble(),
    );
  }

  final String periodKey;
  final double predictedQuantity;
  final double lowerBound;
  final double upperBound;
  final double? actualQuantity;
  final double? absolutePercentageError;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'periodKey': periodKey,
      'predictedQuantity': predictedQuantity,
      'lowerBound': lowerBound,
      'upperBound': upperBound,
      'actualQuantity': actualQuantity,
      'absolutePercentageError': absolutePercentageError,
    };
  }
}

final class DemandForecastDto {
  const DemandForecastDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.scopeType,
    required this.scopeId,
    required this.scopeLabel,
    required this.anchorMonthKey,
    required this.status,
    required this.observedPeriodsCount,
    required this.history,
    required this.forecastPeriods,
    required this.generatedAt,
    required this.updatedAt,
    required this.version,
    this.insufficientDataReason,
    this.model,
    this.modelVersion,
    this.residualStdDev,
  });

  factory DemandForecastDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final scopeType = json['scopeType'];
    final scopeId = json['scopeId'];
    final scopeLabel = json['scopeLabel'];
    final anchorMonthKey = json['anchorMonthKey'];
    final status = json['status'];
    final insufficientDataReason = json['insufficientDataReason'];
    final observedPeriodsCount = json['observedPeriodsCount'];
    final model = json['model'];
    final modelVersion = json['modelVersion'];
    final residualStdDev = json['residualStdDev'];
    final history = json['history'];
    final forecastPeriods = json['forecastPeriods'];
    final generatedAt = json['generatedAt'];
    final updatedAt = json['updatedAt'];
    final version = json['version'];

    if (organizationId is! String ||
        companyId is! String ||
        scopeType is! String ||
        scopeId is! String ||
        scopeLabel is! String ||
        anchorMonthKey is! String ||
        status is! String ||
        (insufficientDataReason != null && insufficientDataReason is! String) ||
        observedPeriodsCount is! int ||
        (model != null && model is! String) ||
        (modelVersion != null && modelVersion is! String) ||
        (residualStdDev != null && residualStdDev is! num) ||
        history is! List ||
        forecastPeriods is! List ||
        generatedAt is! Timestamp ||
        updatedAt is! Timestamp ||
        version is! int) {
      throw const ValidationException(
        'Invalid demand forecast payload.',
        code: 'invalid_demand_forecast_payload',
      );
    }

    return DemandForecastDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      scopeType: scopeType,
      scopeId: scopeId,
      scopeLabel: scopeLabel,
      anchorMonthKey: anchorMonthKey,
      status: status,
      insufficientDataReason: insufficientDataReason as String?,
      observedPeriodsCount: observedPeriodsCount,
      model: model as String?,
      modelVersion: modelVersion as String?,
      residualStdDev: (residualStdDev as num?)?.toDouble(),
      history: history
          .map(
            (entry) => DemandForecastHistoryPointDto.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      forecastPeriods: forecastPeriods
          .map(
            (entry) => DemandForecastPeriodProjectionDto.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      generatedAt: generatedAt.toDate(),
      updatedAt: updatedAt.toDate(),
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String scopeType;
  final String scopeId;
  final String scopeLabel;
  final String anchorMonthKey;
  final String status;
  final String? insufficientDataReason;
  final int observedPeriodsCount;
  final String? model;
  final String? modelVersion;
  final double? residualStdDev;
  final List<DemandForecastHistoryPointDto> history;
  final List<DemandForecastPeriodProjectionDto> forecastPeriods;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'scopeType': scopeType,
      'scopeId': scopeId,
      'scopeLabel': scopeLabel,
      'anchorMonthKey': anchorMonthKey,
      'status': status,
      'insufficientDataReason': insufficientDataReason,
      'observedPeriodsCount': observedPeriodsCount,
      'model': model,
      'modelVersion': modelVersion,
      'residualStdDev': residualStdDev,
      'history': history.map((point) => point.toJson()).toList(),
      'forecastPeriods': forecastPeriods
          .map((period) => period.toJson())
          .toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'version': version,
    };
  }
}
