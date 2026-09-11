import '../../../../core/errors/errors.dart';
import '../../domain/entities/line_sheet.dart';
import '../../domain/entities/line_sheet_order_form.dart';

enum LineSheetLoadStatus { loading, ready, forbidden, failure }

enum LineSheetViewMode { visual, orderForm }

final class LineSheetState {
  const LineSheetState({
    required this.organizationId,
    required this.collectionId,
    required this.profile,
    this.customerId,
    this.status = LineSheetLoadStatus.loading,
    this.viewMode = LineSheetViewMode.visual,
    this.view,
    this.draft,
    this.failure,
  });

  final String organizationId;
  final String collectionId;
  final LineSheetAccessProfile profile;
  final String? customerId;
  final LineSheetLoadStatus status;
  final LineSheetViewMode viewMode;
  final LineSheetView? view;
  final LineSheetOrderFormDraft? draft;
  final Failure? failure;

  LineSheetState copyWith({
    LineSheetLoadStatus? status,
    LineSheetViewMode? viewMode,
    LineSheetView? view,
    LineSheetOrderFormDraft? draft,
    Failure? failure,
  }) {
    return LineSheetState(
      organizationId: organizationId,
      collectionId: collectionId,
      profile: profile,
      customerId: customerId,
      status: status ?? this.status,
      viewMode: viewMode ?? this.viewMode,
      view: view ?? this.view,
      draft: draft ?? this.draft,
      failure: failure,
    );
  }
}
