import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/policy_document.dart';
import '../domain/usecases/policy_acceptance_use_cases.dart';

enum PolicyAcceptanceStatus { loading, ready, accepting, accepted, failure }

final class PolicyAcceptanceState {
  const PolicyAcceptanceState({
    this.status = PolicyAcceptanceStatus.loading,
    this.documents = const <PolicyDocument>[],
    this.acceptanceChecked = false,
    this.failure,
  });

  final PolicyAcceptanceStatus status;
  final List<PolicyDocument> documents;
  final bool acceptanceChecked;
  final Failure? failure;

  PolicyAcceptanceState copyWith({
    PolicyAcceptanceStatus? status,
    List<PolicyDocument>? documents,
    bool? acceptanceChecked,
    Failure? failure,
  }) => PolicyAcceptanceState(
    status: status ?? this.status,
    documents: documents ?? this.documents,
    acceptanceChecked: acceptanceChecked ?? this.acceptanceChecked,
    failure: failure,
  );
}

final class PolicyAcceptanceCubit extends Cubit<PolicyAcceptanceState> {
  PolicyAcceptanceCubit({
    required this.evaluate,
    required this.acceptCurrent,
    required this.getDocuments,
    required this.userId,
    required this.device,
  }) : super(const PolicyAcceptanceState());

  final EvaluatePolicyAcceptanceUseCase evaluate;
  final AcceptCurrentPoliciesUseCase acceptCurrent;
  final GetCurrentPolicyDocumentsUseCase getDocuments;
  final String userId;
  final String device;

  Future<void> load() async {
    emit(state.copyWith(status: PolicyAcceptanceStatus.loading));
    if (userId.isEmpty) {
      final result = await getDocuments();
      switch (result) {
        case AppSuccess<List<PolicyDocument>>(:final value):
          emit(
            state.copyWith(
              status: PolicyAcceptanceStatus.ready,
              documents: value,
            ),
          );
        case AppFailure<List<PolicyDocument>>(:final failure):
          emit(
            state.copyWith(
              status: PolicyAcceptanceStatus.failure,
              failure: failure,
            ),
          );
      }
      return;
    }
    final result = await evaluate(userId);
    switch (result) {
      case AppSuccess<PolicyAcceptanceRequirement>(:final value):
        emit(
          state.copyWith(
            status: value.isSatisfied
                ? PolicyAcceptanceStatus.accepted
                : PolicyAcceptanceStatus.ready,
            documents: value.documents,
          ),
        );
      case AppFailure<PolicyAcceptanceRequirement>(:final failure):
        emit(
          state.copyWith(
            status: PolicyAcceptanceStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void setAcceptanceChecked(bool value) =>
      emit(state.copyWith(acceptanceChecked: value));

  Future<void> submitAcceptance() async {
    if (!state.acceptanceChecked || state.documents.isEmpty) return;
    emit(state.copyWith(status: PolicyAcceptanceStatus.accepting));
    final result = await acceptCurrent(
      userId: userId,
      documents: state.documents,
      acceptedAt: DateTime.now().toUtc(),
      device: device,
    );
    switch (result) {
      case AppSuccess<void>():
        emit(state.copyWith(status: PolicyAcceptanceStatus.accepted));
      case AppFailure<void>(:final failure):
        emit(
          state.copyWith(
            status: PolicyAcceptanceStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
