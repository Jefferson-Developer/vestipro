import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/payment_installment.dart';
import '../../domain/entities/payment_term.dart';
import '../../domain/repositories/payment_term_repository.dart';
import '../../domain/usecases/create_payment_term_use_case.dart';
import '../../domain/usecases/update_payment_term_use_case.dart';
import '../../domain/value_objects/payment_term_status.dart';
import 'payment_terms_state.dart';

@injectable
final class PaymentTermsCubit extends Cubit<PaymentTermsState> {
  PaymentTermsCubit(
    this._repository,
    this._createPaymentTerm,
    this._updatePaymentTerm,
  ) : super(const PaymentTermsState());

  final PaymentTermRepository _repository;
  final CreatePaymentTermUseCase _createPaymentTerm;
  final UpdatePaymentTermUseCase _updatePaymentTerm;
  final Uuid _uuid = const Uuid();

  Future<void> load({
    required String organizationId,
    required String companyId,
    required String userId,
    required String actorName,
  }) async {
    emit(
      state.copyWith(
        loadStatus: PaymentTermsLoadStatus.loading,
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
        actorName: actorName,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
    final result = await _repository.listByCompany(
      organizationId: organizationId,
      companyId: companyId,
    );
    switch (result) {
      case AppSuccess<List<PaymentTerm>>(value: final terms):
        emit(
          state.copyWith(
            loadStatus: PaymentTermsLoadStatus.ready,
            paymentTerms: terms..sort((a, b) => a.name.compareTo(b.name)),
          ),
        );
      case AppFailure<List<PaymentTerm>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: PaymentTermsLoadStatus.failure,
            failureMessage: failure.message,
          ),
        );
    }
  }

  void updateDraft({
    String? name,
    String? installmentsInput,
    String? priceListIdsInput,
    PaymentTermStatus? status,
  }) {
    final nextInstallmentsInput = installmentsInput ?? state.installmentsInput;
    emit(
      state.copyWith(
        saveStatus: PaymentTermsSaveStatus.editing,
        name: name ?? state.name,
        installmentsInput: nextInstallmentsInput,
        priceListIdsInput: priceListIdsInput ?? state.priceListIdsInput,
        status: status ?? state.status,
        installmentsTotal: _sumPercentages(nextInstallmentsInput),
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startCreate() {
    emit(
      state.copyWith(
        saveStatus: PaymentTermsSaveStatus.idle,
        clearEditingId: true,
        name: '',
        installmentsInput: '',
        priceListIdsInput: '',
        status: PaymentTermStatus.active,
        installmentsTotal: 0,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startEdit(PaymentTerm term) {
    emit(
      state.copyWith(
        editingId: term.id,
        saveStatus: PaymentTermsSaveStatus.editing,
        name: term.name,
        installmentsInput: term.installments
            .map(
              (installment) =>
                  '${_formatPercentage(installment.percentage)}:${installment.dueInDays}',
            )
            .join('\n'),
        priceListIdsInput: term.priceListIds.join(', '),
        status: term.status,
        installmentsTotal: term.installments.fold<double>(
          0,
          (sum, installment) => sum + installment.percentage,
        ),
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  Future<void> submit() async {
    emit(
      state.copyWith(
        saveStatus: PaymentTermsSaveStatus.submitting,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );

    final installments = _parseInstallments(state.installmentsInput);
    final priceListIds = state.priceListIdsInput
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    final result = state.isEditing
        ? await _updatePaymentTerm(
            organizationId: state.organizationId,
            id: state.editingId!,
            name: state.name,
            installments: installments,
            priceListIds: priceListIds,
            status: state.status,
            updatedBy: state.userId,
            actorName: state.actorName,
          )
        : await _createPaymentTerm(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            companyId: state.companyId,
            name: state.name,
            installments: installments,
            priceListIds: priceListIds,
            status: state.status,
            createdBy: state.userId,
            actorName: state.actorName,
          );

    switch (result) {
      case AppSuccess<PaymentTerm>():
        await load(
          organizationId: state.organizationId,
          companyId: state.companyId,
          userId: state.userId,
          actorName: state.actorName,
        );
        emit(
          state.copyWith(
            saveStatus: PaymentTermsSaveStatus.success,
            clearEditingId: true,
            name: '',
            installmentsInput: '',
            priceListIdsInput: '',
            status: PaymentTermStatus.active,
            installmentsTotal: 0,
            clearFieldErrors: true,
            clearFailureMessage: true,
          ),
        );
      case AppFailure<PaymentTerm>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: PaymentTermsSaveStatus.failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
            failureMessage: failure.message,
          ),
        );
    }
  }

  List<PaymentInstallment> _parseInstallments(String raw) {
    final lines = raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return lines
        .map((line) {
          final parts = line.split(':');
          final percentage = parts.isEmpty
              ? double.nan
              : _parseDecimal(parts[0]);
          final dueInDays = parts.length < 2
              ? null
              : int.tryParse(parts[1].trim());
          return PaymentInstallment(
            percentage: percentage ?? double.nan,
            dueInDays: dueInDays ?? -1,
          );
        })
        .toList(growable: false);
  }

  double _sumPercentages(String raw) {
    return _parseInstallments(raw).fold<double>(
      0,
      (sum, installment) =>
          sum + (installment.percentage.isNaN ? 0 : installment.percentage),
    );
  }

  double? _parseDecimal(String raw) {
    final normalized = raw.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatPercentage(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
