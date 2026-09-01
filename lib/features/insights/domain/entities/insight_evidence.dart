import 'package:freezed_annotation/freezed_annotation.dart';

part 'insight_evidence.freezed.dart';

@freezed
abstract class InsightEvidence with _$InsightEvidence {
  const factory InsightEvidence({
    required String code,
    required String label,
    required String value,
    double? numericValue,
    String? unit,
  }) = _InsightEvidence;
}
