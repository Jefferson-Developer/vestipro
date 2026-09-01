import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/insight_action_type.dart';

part 'insight_action.freezed.dart';

@freezed
abstract class InsightAction with _$InsightAction {
  const factory InsightAction({
    required InsightActionType type,
    required String label,
    String? route,
    String? customerId,
    String? productId,
    String? sellerId,
    @Default(<String, Object?>{}) Map<String, Object?> payload,
  }) = _InsightAction;
}
