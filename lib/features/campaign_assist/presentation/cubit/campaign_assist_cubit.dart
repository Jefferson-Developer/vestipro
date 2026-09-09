import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../domain/usecases/generate_campaign_creation_draft_use_case.dart';
import 'campaign_assist_state.dart';

/// Drives the "Gerar sugestão com IA" sheet inside `CampaignFormPage`
/// (TASK-192, EPIC-28). Starts at [CampaignAssistStatus.idle] and only ever
/// calls the backend when [generate] is invoked explicitly (a button tap) —
/// never on cubit creation. Mirrors `ApproachSuggestionCubit` (TASK-187).
@injectable
final class CampaignAssistCubit extends Cubit<CampaignAssistState> {
  CampaignAssistCubit(this._generateCampaignCreationDraft)
    : super(const CampaignAssistState());

  final GenerateCampaignCreationDraftUseCase _generateCampaignCreationDraft;

  Future<void> generate({
    required String organizationId,
    List<String> productIds = const <String>[],
    required String audienceDescription,
    required String tone,
    DateTime? startAt,
    DateTime? endAt,
  }) async {
    if (state.status == CampaignAssistStatus.loading) return;
    emit(
      state.copyWith(status: CampaignAssistStatus.loading, clearFailure: true),
    );
    final result = await _generateCampaignCreationDraft(
      organizationId: organizationId,
      productIds: productIds,
      audienceDescription: audienceDescription,
      tone: tone,
      startAt: startAt,
      endAt: endAt,
    );
    if (isClosed) return;
    switch (result) {
      case AppSuccess(value: final draft):
        emit(
          state.copyWith(
            status: CampaignAssistStatus.ready,
            draft: draft,
            clearFailure: true,
          ),
        );
      case AppFailure(failure: final failure):
        emit(
          state.copyWith(status: CampaignAssistStatus.error, failure: failure),
        );
    }
  }

  /// Returns to [CampaignAssistStatus.idle] without clearing a previously
  /// generated [CampaignAssistState.draft] — used when the sheet's "Gerar
  /// novamente" action should show the idle call-to-action/form again.
  void reset() {
    if (state.status == CampaignAssistStatus.loading) return;
    emit(
      CampaignAssistState(
        status: CampaignAssistStatus.idle,
        draft: state.draft,
      ),
    );
  }
}
