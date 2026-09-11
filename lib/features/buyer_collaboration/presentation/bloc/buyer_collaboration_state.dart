import '../../../../core/errors/errors.dart';
import '../../domain/entities/buyer_collaboration_comment.dart';
import '../../domain/entities/buyer_collaboration_conversion_result.dart';
import '../../domain/entities/buyer_collaboration_session.dart';

enum BuyerCollaborationLoadStatus { idle, loading, ready, failure }

enum BuyerCollaborationActionStatus { idle, submitting, success, failure }

final class BuyerCollaborationState {
  const BuyerCollaborationState({
    this.loadStatus = BuyerCollaborationLoadStatus.idle,
    this.session,
    this.comments = const <BuyerCollaborationComment>[],
    this.loadFailure,
    this.actionStatus = BuyerCollaborationActionStatus.idle,
    this.actionFailure,
    this.lastConversion,
    this.createdSessionId,
  });

  final BuyerCollaborationLoadStatus loadStatus;
  final BuyerCollaborationSession? session;
  final List<BuyerCollaborationComment> comments;
  final Failure? loadFailure;
  final BuyerCollaborationActionStatus actionStatus;
  final Failure? actionFailure;
  final BuyerCollaborationConversionResult? lastConversion;
  final String? createdSessionId;
}
