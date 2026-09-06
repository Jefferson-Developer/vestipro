import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../core/utils/utils.dart';
import '../domain/usecases/request_account_deletion.dart';

enum AccountDeletionStatus { idle, submitting, completed, failure }

final class AccountDeletionState {
  const AccountDeletionState({
    this.status = AccountDeletionStatus.idle,
    this.failure,
  });

  final AccountDeletionStatus status;
  final Failure? failure;
}

final class AccountDeletionCubit extends Cubit<AccountDeletionState> {
  AccountDeletionCubit({
    required this.requestAccountDeletion,
    required this.organizationId,
  }) : super(const AccountDeletionState());

  final RequestAccountDeletion requestAccountDeletion;
  final String organizationId;

  Future<void> submit(String confirmation) async {
    if (state.status == AccountDeletionStatus.submitting) return;
    emit(const AccountDeletionState(status: AccountDeletionStatus.submitting));
    final result = await requestAccountDeletion(
      organizationId: organizationId,
      confirmation: confirmation,
    );
    switch (result) {
      case AppSuccess():
        emit(
          const AccountDeletionState(status: AccountDeletionStatus.completed),
        );
      case AppFailure(:final failure):
        emit(
          AccountDeletionState(
            status: AccountDeletionStatus.failure,
            failure: failure,
          ),
        );
    }
  }
}
