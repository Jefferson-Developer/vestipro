import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/buyer_collaboration_attachment.dart';
import '../../domain/entities/buyer_collaboration_comment.dart';
import '../../domain/entities/buyer_collaboration_conversion_result.dart';
import '../../domain/entities/buyer_collaboration_item.dart';
import '../../domain/entities/buyer_collaboration_proposed_change.dart';
import '../../domain/entities/buyer_collaboration_session.dart';
import '../../domain/usecases/buyer_collaboration_use_cases.dart';
import '../../domain/value_objects/buyer_collaboration_comment_kind.dart';
import '../../domain/value_objects/buyer_collaboration_source_type.dart';
import 'buyer_collaboration_state.dart';

/// Owns one `BuyerCollaborationSession`'s screen state (TASK-211): the
/// session document and its comment history each stream independently from
/// Firestore (read-only, RBAC enforced by `firestore.rules`), while every
/// mutation goes through the `buyer_collaboration` Cloud Functions. Reused
/// as-is by both the seller's panel (opened from the order draft) and the
/// buyer's own customer-portal screen — which actions are actually offered
/// is a `presentation/widgets` concern driven by the caller's role, not
/// this Cubit's.
@injectable
final class BuyerCollaborationCubit extends Cubit<BuyerCollaborationState> {
  BuyerCollaborationCubit({
    required this.createSession,
    required this.shareSession,
    required this.addCommentUseCase,
    required this.requestChangesUseCase,
    required this.approveUseCase,
    required this.convertUseCase,
    required this.reopenUseCase,
    required this.watchSessionUseCase,
    required this.watchCommentsUseCase,
    required this.analytics,
  }) : super(const BuyerCollaborationState());

  final CreateBuyerCollaborationSessionUseCase createSession;
  final ShareBuyerCollaborationSessionUseCase shareSession;
  final AddBuyerCollaborationCommentUseCase addCommentUseCase;
  final RequestBuyerCollaborationChangesUseCase requestChangesUseCase;
  final ApproveBuyerCollaborationSessionUseCase approveUseCase;
  final ConvertBuyerCollaborationSessionUseCase convertUseCase;
  final ReopenBuyerCollaborationSessionUseCase reopenUseCase;
  final WatchBuyerCollaborationSessionUseCase watchSessionUseCase;
  final WatchBuyerCollaborationCommentsUseCase watchCommentsUseCase;
  final AnalyticsService analytics;

  StreamSubscription<AppResult<BuyerCollaborationSession?>>?
  _sessionSubscription;
  StreamSubscription<AppResult<List<BuyerCollaborationComment>>>?
  _commentsSubscription;

  void watch({required String organizationId, required String sessionId}) {
    emit(
      BuyerCollaborationState(
        loadStatus: BuyerCollaborationLoadStatus.loading,
        session: state.session,
        comments: state.comments,
      ),
    );
    unawaited(_sessionSubscription?.cancel());
    unawaited(_commentsSubscription?.cancel());
    _sessionSubscription =
        watchSessionUseCase(
          organizationId: organizationId,
          sessionId: sessionId,
        ).listen((result) {
          switch (result) {
            case AppSuccess<BuyerCollaborationSession?>(value: final session):
              emit(
                BuyerCollaborationState(
                  loadStatus: BuyerCollaborationLoadStatus.ready,
                  session: session,
                  comments: state.comments,
                  actionStatus: state.actionStatus,
                ),
              );
            case AppFailure<BuyerCollaborationSession?>(failure: final failure):
              emit(
                BuyerCollaborationState(
                  loadStatus: BuyerCollaborationLoadStatus.failure,
                  session: state.session,
                  comments: state.comments,
                  loadFailure: failure,
                ),
              );
          }
        });
    _commentsSubscription =
        watchCommentsUseCase(
          organizationId: organizationId,
          sessionId: sessionId,
        ).listen((result) {
          switch (result) {
            case AppSuccess<List<BuyerCollaborationComment>>(
              value: final comments,
            ):
              emit(
                BuyerCollaborationState(
                  loadStatus:
                      state.loadStatus == BuyerCollaborationLoadStatus.idle
                      ? BuyerCollaborationLoadStatus.ready
                      : state.loadStatus,
                  session: state.session,
                  comments: comments,
                  actionStatus: state.actionStatus,
                ),
              );
            case AppFailure<List<BuyerCollaborationComment>>(
              failure: final failure,
            ):
              emit(
                BuyerCollaborationState(
                  loadStatus: state.loadStatus,
                  session: state.session,
                  comments: state.comments,
                  loadFailure: failure,
                ),
              );
          }
        });
  }

  Future<void> create({
    required String organizationId,
    required String companyId,
    required String customerId,
    required String priceListId,
    required BuyerCollaborationSourceType sourceType,
    required String sourceId,
    required List<BuyerCollaborationItem> items,
    required bool showPrices,
  }) async {
    emit(
      BuyerCollaborationState(
        session: state.session,
        comments: state.comments,
        actionStatus: BuyerCollaborationActionStatus.submitting,
      ),
    );
    final result = await createSession(
      organizationId: organizationId,
      companyId: companyId,
      customerId: customerId,
      priceListId: priceListId,
      sourceType: sourceType,
      sourceId: sourceId,
      items: items,
      showPrices: showPrices,
    );
    switch (result) {
      case AppSuccess<String>(value: final sessionId):
        emit(
          BuyerCollaborationState(
            session: state.session,
            comments: state.comments,
            actionStatus: BuyerCollaborationActionStatus.success,
            createdSessionId: sessionId,
          ),
        );
        await analytics.logEvent(
          AnalyticsEvents.buyerCollaborationSessionOpened,
          parameters: <String, Object?>{
            'source_type': sourceType.code,
            'items_count': items.length,
          },
        );
      case AppFailure<String>(failure: final failure):
        emit(
          BuyerCollaborationState(
            session: state.session,
            comments: state.comments,
            actionStatus: BuyerCollaborationActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  Future<void> share({
    required String organizationId,
    required String sessionId,
    List<BuyerCollaborationItem>? items,
    String? note,
  }) => _runAction(
    () => shareSession(
      organizationId: organizationId,
      sessionId: sessionId,
      items: items,
      note: note,
    ),
  );

  Future<void> addComment({
    required String organizationId,
    required String sessionId,
    required String body,
    String? itemId,
    BuyerCollaborationCommentVisibility visibility =
        BuyerCollaborationCommentVisibility.shared,
    List<BuyerCollaborationAttachment> attachments =
        const <BuyerCollaborationAttachment>[],
    List<String> mentionedMemberIds = const <String>[],
  }) => _runAction(() async {
    final result = await addCommentUseCase(
      organizationId: organizationId,
      sessionId: sessionId,
      body: body,
      itemId: itemId,
      visibility: visibility,
      attachments: attachments,
      mentionedMemberIds: mentionedMemberIds,
    );
    if (result is AppSuccess<void>) {
      await analytics.logEvent(
        AnalyticsEvents.buyerCollaborationCommentAdded,
        parameters: <String, Object?>{
          'has_item': itemId != null,
          'visibility': visibility.code,
        },
      );
    }
    return result;
  });

  Future<void> requestChanges({
    required String organizationId,
    required String sessionId,
    required String comment,
    List<BuyerCollaborationProposedChange> proposedChanges =
        const <BuyerCollaborationProposedChange>[],
  }) => _runAction(() async {
    final result = await requestChangesUseCase(
      organizationId: organizationId,
      sessionId: sessionId,
      comment: comment,
      proposedChanges: proposedChanges,
    );
    if (result is AppSuccess<void>) {
      await analytics.logEvent(
        AnalyticsEvents.buyerCollaborationChangesRequested,
        parameters: <String, Object?>{
          'proposed_changes_count': proposedChanges.length,
        },
      );
    }
    return result;
  });

  Future<void> approve({
    required String organizationId,
    required String sessionId,
    String? comment,
  }) => _runAction(() async {
    final result = await approveUseCase(
      organizationId: organizationId,
      sessionId: sessionId,
      comment: comment,
    );
    if (result is AppSuccess<void>) {
      await analytics.logEvent(AnalyticsEvents.buyerCollaborationApproved);
    }
    return result;
  });

  Future<void> convert({
    required String organizationId,
    required String sessionId,
    required String orderId,
    bool acceptPriceDrift = false,
  }) async {
    emit(
      BuyerCollaborationState(
        session: state.session,
        comments: state.comments,
        actionStatus: BuyerCollaborationActionStatus.submitting,
      ),
    );
    final result = await convertUseCase(
      organizationId: organizationId,
      sessionId: sessionId,
      orderId: orderId,
      acceptPriceDrift: acceptPriceDrift,
    );
    switch (result) {
      case AppSuccess<BuyerCollaborationConversionResult>(
        value: final conversion,
      ):
        emit(
          BuyerCollaborationState(
            session: state.session,
            comments: state.comments,
            actionStatus: BuyerCollaborationActionStatus.success,
            lastConversion: conversion,
          ),
        );
        if (conversion.converted) {
          await analytics.logEvent(
            AnalyticsEvents.buyerCollaborationConvertedToOrder,
            parameters: <String, Object?>{'order_id': conversion.orderId},
          );
        }
      case AppFailure<BuyerCollaborationConversionResult>(
        failure: final failure,
      ):
        emit(
          BuyerCollaborationState(
            session: state.session,
            comments: state.comments,
            actionStatus: BuyerCollaborationActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  Future<void> reopen({
    required String organizationId,
    required String sessionId,
  }) => _runAction(
    () => reopenUseCase(organizationId: organizationId, sessionId: sessionId),
  );

  Future<void> _runAction(Future<AppResult<void>> Function() action) async {
    emit(
      BuyerCollaborationState(
        session: state.session,
        comments: state.comments,
        actionStatus: BuyerCollaborationActionStatus.submitting,
      ),
    );
    final result = await action();
    switch (result) {
      case AppSuccess<void>():
        emit(
          BuyerCollaborationState(
            session: state.session,
            comments: state.comments,
            actionStatus: BuyerCollaborationActionStatus.success,
          ),
        );
      case AppFailure<void>(failure: final failure):
        emit(
          BuyerCollaborationState(
            session: state.session,
            comments: state.comments,
            actionStatus: BuyerCollaborationActionStatus.failure,
            actionFailure: failure,
          ),
        );
    }
  }

  @override
  Future<void> close() async {
    await _sessionSubscription?.cancel();
    await _commentsSubscription?.cancel();
    return super.close();
  }
}
