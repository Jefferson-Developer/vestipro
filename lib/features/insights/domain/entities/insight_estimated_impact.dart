import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_estimated_impact.freezed.dart';

@freezed
abstract class InsightEstimatedImpact with _$InsightEstimatedImpact {
  const InsightEstimatedImpact._();

  const factory InsightEstimatedImpact({
    double? amount,
    double? percentage,
    @Default('BRL') String currencyCode,
  }) = _InsightEstimatedImpact;

  bool get hasValue => amount != null || percentage != null;
}
