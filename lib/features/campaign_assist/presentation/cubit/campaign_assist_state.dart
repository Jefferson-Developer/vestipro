import '../../../../core/errors/errors.dart';
import '../../domain/entities/campaign_creation_draft.dart';

enum CampaignAssistStatus {
  /// Before the admin ever taps "Gerar sugestão com IA" — never
  /// auto-generates on sheet open (same "sob demanda" posture as
  /// `ApproachSuggestionStatus.idle`, TASK-187), also keeps LLM cost/
  /// frequency under the caller's control.
  idle,
  loading,
  ready,
  error,
}

/// State for [CampaignAssistCubit] (TASK-192, EPIC-28).
final class CampaignAssistState {
  const CampaignAssistState({
    this.status = CampaignAssistStatus.idle,
    this.draft,
    this.failure,
  });

  final CampaignAssistStatus status;
  final CampaignCreationDraft? draft;
  final Failure? failure;

  CampaignAssistState copyWith({
    CampaignAssistStatus? status,
    CampaignCreationDraft? draft,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return CampaignAssistState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}
