import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/consent_record.dart';
import '../domain/repositories/consent_repository.dart';
import '../domain/usecases/consent_use_cases.dart';

enum ConsentManagementStatus { loading, ready, failure }

final class ConsentManagementState {
  const ConsentManagementState({
    this.status = ConsentManagementStatus.loading,
    this.effective = const <ConsentPurpose, ConsentRecord>{},
    this.updating = const <ConsentPurpose>{},
    this.failure,
  });

  final ConsentManagementStatus status;
  final Map<ConsentPurpose, ConsentRecord> effective;
  final Set<ConsentPurpose> updating;
  final Failure? failure;

  ConsentManagementState copyWith({
    ConsentManagementStatus? status,
    Map<ConsentPurpose, ConsentRecord>? effective,
    Set<ConsentPurpose>? updating,
    Failure? failure,
  }) => ConsentManagementState(
    status: status ?? this.status,
    effective: effective ?? this.effective,
    updating: updating ?? this.updating,
    failure: failure,
  );
}

final class ConsentManagementCubit extends Cubit<ConsentManagementState> {
  ConsentManagementCubit({
    required this.repository,
    required this.grantConsent,
    required this.revokeConsent,
    required this.organizationId,
    required this.userId,
  }) : super(const ConsentManagementState());

  final ConsentRepository repository;
  final GrantConsent grantConsent;
  final RevokeConsent revokeConsent;
  final String organizationId;
  final String userId;
  StreamSubscription<AppResult<List<ConsentRecord>>>? _subscription;

  Future<void> load() async {
    emit(state.copyWith(status: ConsentManagementStatus.loading));
    final previousSubscription = _subscription;
    if (previousSubscription != null) await previousSubscription.cancel();
    _subscription = repository
        .watchUserConsents(organizationId: organizationId, userId: userId)
        .listen(_onRecords, onError: _onStreamError);
  }

  Future<void> setConsent(ConsentPurpose purpose, bool granted) async {
    if (state.updating.contains(purpose) ||
        (state.effective[purpose]?.granted ?? false) == granted) {
      return;
    }
    emit(
      state.copyWith(updating: <ConsentPurpose>{...state.updating, purpose}),
    );
    final now = DateTime.now().toUtc();
    final result = granted
        ? await grantConsent(
            organizationId: organizationId,
            userId: userId,
            purpose: purpose,
            grantedAt: now,
          )
        : await revokeConsent(
            organizationId: organizationId,
            userId: userId,
            purpose: purpose,
            revokedAt: now,
          );
    switch (result) {
      case AppSuccess<void>():
        emit(
          state.copyWith(
            updating: <ConsentPurpose>{...state.updating}..remove(purpose),
          ),
        );
      case AppFailure<void>(:final failure):
        emit(
          state.copyWith(
            status: ConsentManagementStatus.failure,
            updating: <ConsentPurpose>{...state.updating}..remove(purpose),
            failure: failure,
          ),
        );
    }
  }

  void _onRecords(AppResult<List<ConsentRecord>> result) {
    switch (result) {
      case AppSuccess<List<ConsentRecord>>(:final value):
        emit(
          state.copyWith(
            status: ConsentManagementStatus.ready,
            effective: effectiveConsents(value),
          ),
        );
      case AppFailure<List<ConsentRecord>>(:final failure):
        emit(
          state.copyWith(
            status: ConsentManagementStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) => emit(
    state.copyWith(
      status: ConsentManagementStatus.failure,
      failure: UnexpectedFailure(
        'Não foi possível acompanhar os consentimentos.',
        code: 'consent_stream_unexpected',
        cause: error,
      ),
    ),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
