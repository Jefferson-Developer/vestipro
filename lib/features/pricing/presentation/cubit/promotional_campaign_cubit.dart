import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/promotional_campaign.dart';
import '../../domain/repositories/promotional_campaign_repository.dart';
import '../../domain/usecases/create_promotional_campaign_use_case.dart';
import '../../domain/usecases/update_promotional_campaign_use_case.dart';
import '../../domain/value_objects/promotional_campaign_status.dart';
import '../../domain/value_objects/promotional_discount_type.dart';
import 'promotional_campaign_state.dart';

@injectable
final class PromotionalCampaignCubit extends Cubit<PromotionalCampaignState> {
  PromotionalCampaignCubit(
    this._repository,
    this._createCampaign,
    this._updateCampaign,
  ) : super(const PromotionalCampaignState());

  final PromotionalCampaignRepository _repository;
  final CreatePromotionalCampaignUseCase _createCampaign;
  final UpdatePromotionalCampaignUseCase _updateCampaign;
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
        loadStatus: PromotionalCampaignLoadStatus.loading,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
    final result = await _repository.listByCompany(
      organizationId: organizationId,
      companyId: companyId,
    );
    switch (result) {
      case AppSuccess<List<PromotionalCampaign>>(value: final campaigns):
        campaigns.sort((a, b) {
          final byPriority = b.priority.compareTo(a.priority);
          if (byPriority != 0) return byPriority;
          return a.name.compareTo(b.name);
        });
        emit(
          state.copyWith(
            loadStatus: PromotionalCampaignLoadStatus.ready,
            campaigns: campaigns,
          ),
        );
      case AppFailure<List<PromotionalCampaign>>(failure: final failure):
        emit(
          state.copyWith(
            loadStatus: PromotionalCampaignLoadStatus.failure,
            failureMessage: failure.message,
          ),
        );
    }
  }

  void updateDraft({
    String? name,
    String? customerSegment,
    String? productIdsInput,
    String? collectionIdsInput,
    String? categoryIdsInput,
    String? discountValueInput,
    String? priorityInput,
    DateTime? validFrom,
    DateTime? validTo,
    bool? stackableWithOtherCampaigns,
    PromotionalDiscountType? discountType,
    PromotionalCampaignStatus? status,
  }) {
    emit(
      state.copyWith(
        saveStatus: PromotionalCampaignSaveStatus.editing,
        name: name ?? state.name,
        customerSegment: customerSegment ?? state.customerSegment,
        productIdsInput: productIdsInput ?? state.productIdsInput,
        collectionIdsInput: collectionIdsInput ?? state.collectionIdsInput,
        categoryIdsInput: categoryIdsInput ?? state.categoryIdsInput,
        discountValueInput: discountValueInput ?? state.discountValueInput,
        priorityInput: priorityInput ?? state.priorityInput,
        validFrom: validFrom ?? state.validFrom,
        validTo: validTo ?? state.validTo,
        stackableWithOtherCampaigns:
            stackableWithOtherCampaigns ?? state.stackableWithOtherCampaigns,
        discountType: discountType ?? state.discountType,
        status: status ?? state.status,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startCreate() {
    emit(
      state.copyWith(
        saveStatus: PromotionalCampaignSaveStatus.idle,
        clearEditingId: true,
        name: '',
        customerSegment: '',
        productIdsInput: '',
        collectionIdsInput: '',
        categoryIdsInput: '',
        discountValueInput: '',
        priorityInput: '0',
        clearValidFrom: true,
        clearValidTo: true,
        stackableWithOtherCampaigns: false,
        discountType: PromotionalDiscountType.percentage,
        status: PromotionalCampaignStatus.active,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  void startEdit(PromotionalCampaign campaign) {
    emit(
      state.copyWith(
        editingId: campaign.id,
        saveStatus: PromotionalCampaignSaveStatus.editing,
        name: campaign.name,
        customerSegment: campaign.customerSegment,
        productIdsInput: campaign.productIds.join(', '),
        collectionIdsInput: campaign.collectionIds.join(', '),
        categoryIdsInput: campaign.categoryIds.join(', '),
        discountValueInput: _formatNumber(campaign.discountValue),
        priorityInput: campaign.priority.toString(),
        validFrom: campaign.validFrom,
        validTo: campaign.validTo,
        stackableWithOtherCampaigns: campaign.stackableWithOtherCampaigns,
        discountType: campaign.discountType,
        status: campaign.status,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );
  }

  Future<void> submit() async {
    emit(
      state.copyWith(
        saveStatus: PromotionalCampaignSaveStatus.submitting,
        clearFieldErrors: true,
        clearFailureMessage: true,
      ),
    );

    final discountValue = _parseDecimal(state.discountValueInput);
    final priority = int.tryParse(state.priorityInput.trim());
    final validFrom = state.validFrom;
    final validTo = state.validTo;

    if (validFrom == null || validTo == null) {
      emit(
        state.copyWith(
          saveStatus: PromotionalCampaignSaveStatus.failure,
          fieldErrors: <String, String>{
            if (validFrom == null) 'validFrom': 'Informe o início da vigência.',
            if (validTo == null) 'validTo': 'Informe o fim da vigência.',
          },
        ),
      );
      return;
    }

    final result = state.isEditing
        ? await _updateCampaign(
            organizationId: state.organizationId,
            id: state.editingId!,
            name: state.name,
            validFrom: validFrom,
            validTo: validTo,
            customerSegment: state.customerSegment,
            productIds: _split(state.productIdsInput),
            collectionIds: _split(state.collectionIdsInput),
            categoryIds: _split(state.categoryIdsInput),
            discountType: state.discountType,
            discountValue: discountValue ?? double.nan,
            stackableWithOtherCampaigns: state.stackableWithOtherCampaigns,
            priority: priority ?? -1,
            status: state.status,
            updatedBy: state.userId,
            actorName: state.actorName,
          )
        : await _createCampaign(
            id: _uuid.v4(),
            organizationId: state.organizationId,
            companyId: state.companyId,
            name: state.name,
            validFrom: validFrom,
            validTo: validTo,
            customerSegment: state.customerSegment,
            productIds: _split(state.productIdsInput),
            collectionIds: _split(state.collectionIdsInput),
            categoryIds: _split(state.categoryIdsInput),
            discountType: state.discountType,
            discountValue: discountValue ?? double.nan,
            stackableWithOtherCampaigns: state.stackableWithOtherCampaigns,
            priority: priority ?? -1,
            status: state.status,
            createdBy: state.userId,
            actorName: state.actorName,
          );

    switch (result) {
      case AppSuccess<PromotionalCampaign>():
        await load(
          organizationId: state.organizationId,
          companyId: state.companyId,
          userId: state.userId,
          actorName: state.actorName,
        );
        emit(
          state.copyWith(
            saveStatus: PromotionalCampaignSaveStatus.success,
            clearEditingId: true,
            name: '',
            customerSegment: '',
            productIdsInput: '',
            collectionIdsInput: '',
            categoryIdsInput: '',
            discountValueInput: '',
            priorityInput: '0',
            clearValidFrom: true,
            clearValidTo: true,
            stackableWithOtherCampaigns: false,
            discountType: PromotionalDiscountType.percentage,
            status: PromotionalCampaignStatus.active,
            clearFieldErrors: true,
            clearFailureMessage: true,
          ),
        );
      case AppFailure<PromotionalCampaign>(failure: final failure):
        emit(
          state.copyWith(
            saveStatus: PromotionalCampaignSaveStatus.failure,
            fieldErrors: failure is ValidationFailure
                ? failure.fieldErrors
                : const <String, String>{},
            failureMessage: failure.message,
          ),
        );
    }
  }

  List<String> _split(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  double? _parseDecimal(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
