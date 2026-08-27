import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/discount_policy.dart';
import '../../domain/repositories/discount_policy_repository.dart';
import '../../domain/usecases/create_discount_policy_use_case.dart';
import '../../domain/usecases/update_discount_policy_use_case.dart';
import '../../domain/value_objects/discount_policy_status.dart';
import 'discount_policy_state.dart';

@injectable
final class DiscountPolicyCubit extends Cubit<DiscountPolicyState> {
  DiscountPolicyCubit(
    this._repository,
    this._createDiscountPolicy,
    this._updateDiscountPolicy,
  ) : super(const DiscountPolicyState());

  final DiscountPolicyRepository _repository;
  final CreateDiscountPolicyUseCase _createDiscountPolicy;
  final UpdateDiscountPolicyUseCase _updateDiscountPolicy;
  final Uuid _uuid = const Uuid();

  Future<void> load({
    required String organizationId,
    required String companyId,
    required String userId,
    required String actorName,
  }) async {
    emit(
      state.copyWith(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        actorName: actorName,
        loadStatus: DiscountPolicyLoadStatus.loading,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );

    final result = await _repository.listByCompany(
      organizationId: organizationId,
      companyId: companyId,
    );
    switch (result) {
      case AppSuccess<List<DiscountPolicy>>(value: final items):
        items.sort((a, b) => a.role.compareTo(b.role));
        emit(
          state.copyWith(
            loadStatus: DiscountPolicyLoadStatus.ready,
            policies: items,
          ),
        );
      case AppFailure<List<DiscountPolicy>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: DiscountPolicyLoadStatus.failure,
            failureMessage: failure.message,
          ),
        );
    }
  }

  void updateDraft({
    String? role,
    String? maxDiscountPercentInput,
    String? requiresApprovalAbovePercentInput,
    String? priceListIdsInput,
    DiscountPolicyStatus? status,
  }) {
    emit(
      state.copyWith(
        saveStatus: DiscountPolicySaveStatus.editing,
        role: role ?? state.role,
        maxDiscountPercentInput:
            maxDiscountPercentInput ?? state.maxDiscountPercentInput,
        requiresApprovalAbovePercentInput:
            requiresApprovalAbovePercentInput ??
            state.requiresApprovalAbovePercentInput,
        priceListIdsInput: priceListIdsInput ?? state.priceListIdsInput,
        status: status ?? state.status,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startCreate() {
    emit(
      state.copyWith(
        saveStatus: DiscountPolicySaveStatus.idle,
        clearEditingId: true,
        role: '',
        maxDiscountPercentInput: '',
        requiresApprovalAbovePercentInput: '',
        priceListIdsInput: '',
        status: DiscountPolicyStatus.active,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startEdit(DiscountPolicy policy) {
    emit(
      state.copyWith(
        editingId: policy.id,
        saveStatus: DiscountPolicySaveStatus.editing,
        role: policy.role,
        maxDiscountPercentInput: _formatNumber(policy.maxDiscountPercent),
        requiresApprovalAbovePercentInput:
            policy.requiresApprovalAbovePercent == null
            ? ''
            : _formatNumber(policy.requiresApprovalAbovePercent!),
        priceListIdsInput: policy.priceListIds.join(', '),
        status: policy.status,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  Future<void> submit() async {
    emit(
      state.copyWith(
        saveStatus: DiscountPolicySaveStatus.submitting,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );

    final maxDiscount = _parseDecimal(state.maxDiscountPercentInput);
    final approvalThreshold =
        state.requiresApprovalAbovePercentInput.trim().isEmpty
        ? null
        : _parseDecimal(state.requiresApprovalAbovePercentInput);
    final priceListIds = state.priceListIdsInput
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    final result = state.isEditing
        ? await _updateDiscountPolicy(
            organizationId: state.organizationId,
            id: state.editingId!,
            role: state.role,
            maxDiscountPercent: maxDiscount ?? double.nan,
            priceListIds: priceListIds,
            requiresApprovalAbovePercent: approvalThreshold,
            status: state.status,
            updatedBy: state.userId,
            actorName: state.actorName,
          )
        : await _createDiscountPolicy(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            companyId: state.companyId,
            role: state.role,
            maxDiscountPercent: maxDiscount ?? double.nan,
            priceListIds: priceListIds,
            requiresApprovalAbovePercent: approvalThreshold,
            status: state.status,
            createdBy: state.userId,
            actorName: state.actorName,
          );

    switch (result) {
      case AppSuccess<DiscountPolicy>():
        await load(
          organizationId: state.organizationId,
          companyId: state.companyId,
          userId: state.userId,
          actorName: state.actorName,
        );
        emit(
          state.copyWith(
            saveStatus: DiscountPolicySaveStatus.success,
            clearEditingId: true,
            role: '',
            maxDiscountPercentInput: '',
            requiresApprovalAbovePercentInput: '',
            priceListIdsInput: '',
            status: DiscountPolicyStatus.active,
            clearFieldErrors: true,
            clearFailureMessage: true,
          ),
        );
      case AppFailure<DiscountPolicy>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: DiscountPolicySaveStatus.failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
            failureMessage: failure.message,
          ),
        );
    }
  }

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
