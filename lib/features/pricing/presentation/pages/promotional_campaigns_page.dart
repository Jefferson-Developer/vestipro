import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/promotional_campaign.dart';
import '../../domain/value_objects/promotional_campaign_status.dart';
import '../../domain/value_objects/promotional_discount_type.dart';
import '../cubit/promotional_campaign_cubit.dart';
import '../cubit/promotional_campaign_state.dart';

class PromotionalCampaignsPage extends StatelessWidget {
  const PromotionalCampaignsPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.actorName,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;
  final PermissionService permissionService;
  final PromotionalCampaignCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.priceListManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<PromotionalCampaignCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
                actorName: actorName,
              ),
            );
            return cubit;
          },
          child: const _PromotionalCampaignsView(),
        );
      },
    );
  }
}

class _PromotionalCampaignsView extends StatefulWidget {
  const _PromotionalCampaignsView();

  @override
  State<_PromotionalCampaignsView> createState() =>
      _PromotionalCampaignsViewState();
}

class _PromotionalCampaignsViewState extends State<_PromotionalCampaignsView> {
  final _nameController = TextEditingController();
  final _segmentController = TextEditingController();
  final _productIdsController = TextEditingController();
  final _collectionIdsController = TextEditingController();
  final _categoryIdsController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _priorityController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _segmentController.dispose();
    _productIdsController.dispose();
    _collectionIdsController.dispose();
    _categoryIdsController.dispose();
    _discountValueController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PromotionalCampaignCubit, PromotionalCampaignState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.name != current.name ||
          previous.customerSegment != current.customerSegment ||
          previous.productIdsInput != current.productIdsInput ||
          previous.collectionIdsInput != current.collectionIdsInput ||
          previous.categoryIdsInput != current.categoryIdsInput ||
          previous.discountValueInput != current.discountValueInput ||
          previous.priorityInput != current.priorityInput,
      listener: (context, state) {
        _sync(_nameController, state.name);
        _sync(_segmentController, state.customerSegment);
        _sync(_productIdsController, state.productIdsInput);
        _sync(_collectionIdsController, state.collectionIdsInput);
        _sync(_categoryIdsController, state.categoryIdsInput);
        _sync(_discountValueController, state.discountValueInput);
        _sync(_priorityController, state.priorityInput);
        if (state.saveStatus == PromotionalCampaignSaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Campanha promocional salva.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == PromotionalCampaignSaveStatus.failure &&
            state.failureMessage != null &&
            state.fieldErrors.isEmpty) {
          AppSnackbar.show(
            context,
            message: state.failureMessage!,
            variant: AppSnackbarVariant.error,
          );
        }
      },
      builder: (context, state) {
        _sync(_nameController, state.name);
        _sync(_segmentController, state.customerSegment);
        _sync(_productIdsController, state.productIdsInput);
        _sync(_collectionIdsController, state.collectionIdsInput);
        _sync(_categoryIdsController, state.categoryIdsInput);
        _sync(_discountValueController, state.discountValueInput);
        _sync(_priorityController, state.priorityInput);
        final cubit = context.read<PromotionalCampaignCubit>();

        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Campanhas promocionais',
            actions: <Widget>[
              AppButton(
                label: state.isEditing ? 'Nova campanha' : 'Limpar formulário',
                leadingIcon: Icons.campaign_outlined,
                onPressed: state.isBusy ? null : cubit.startCreate,
              ),
            ],
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    controller: _nameController,
                    label: 'Nome da campanha',
                    semanticLabel: 'Nome da campanha promocional',
                    isRequired: true,
                    errorText: state.fieldErrors['name'],
                    onChanged: (value) => cubit.updateDraft(name: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppTextField(
                    controller: _segmentController,
                    label: 'Segmento de cliente',
                    semanticLabel: 'Segmento de cliente da campanha',
                    isRequired: true,
                    errorText: state.fieldErrors['customerSegment'],
                    onChanged: (value) =>
                        cubit.updateDraft(customerSegment: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppTextField(
                    controller: _productIdsController,
                    label: 'Produtos elegíveis',
                    semanticLabel: 'Produtos elegíveis da campanha',
                    hintText: 'product-1, product-2',
                    errorText: state.fieldErrors['productScope'],
                    onChanged: (value) =>
                        cubit.updateDraft(productIdsInput: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppTextField(
                    controller: _collectionIdsController,
                    label: 'Coleções elegíveis',
                    semanticLabel: 'Coleções elegíveis da campanha',
                    hintText: 'collection-1',
                    onChanged: (value) =>
                        cubit.updateDraft(collectionIdsInput: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppTextField(
                    controller: _categoryIdsController,
                    label: 'Categorias elegíveis',
                    semanticLabel: 'Categorias elegíveis da campanha',
                    hintText: 'category-1',
                    onChanged: (value) =>
                        cubit.updateDraft(categoryIdsInput: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          controller: _discountValueController,
                          label: 'Valor do desconto',
                          semanticLabel: 'Valor do desconto da campanha',
                          isRequired: true,
                          errorText: state.fieldErrors['discountValue'],
                          onChanged: (value) =>
                              cubit.updateDraft(discountValueInput: value),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        child: AppTextField(
                          controller: _priorityController,
                          label: 'Prioridade',
                          semanticLabel: 'Prioridade da campanha',
                          isRequired: true,
                          errorText: state.fieldErrors['priority'],
                          onChanged: (value) =>
                              cubit.updateDraft(priorityInput: value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppDropdown<PromotionalDiscountType>(
                    options: const <AppDropdownOption<PromotionalDiscountType>>[
                      AppDropdownOption(
                        value: PromotionalDiscountType.percentage,
                        label: 'Percentual',
                      ),
                      AppDropdownOption(
                        value: PromotionalDiscountType.fixedAmount,
                        label: 'Valor fixo',
                      ),
                    ],
                    selectedValues: <PromotionalDiscountType>{
                      state.discountType,
                    },
                    onChanged: (values) =>
                        cubit.updateDraft(discountType: values.first),
                    closeSemanticLabel: 'Fechar seleção do tipo de desconto',
                    label: 'Tipo de desconto',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppDropdown<PromotionalCampaignStatus>(
                    options:
                        const <AppDropdownOption<PromotionalCampaignStatus>>[
                          AppDropdownOption(
                            value: PromotionalCampaignStatus.active,
                            label: 'Ativa',
                          ),
                          AppDropdownOption(
                            value: PromotionalCampaignStatus.draft,
                            label: 'Rascunho',
                          ),
                          AppDropdownOption(
                            value: PromotionalCampaignStatus.ended,
                            label: 'Encerrada',
                          ),
                        ],
                    selectedValues: <PromotionalCampaignStatus>{state.status},
                    onChanged: (values) =>
                        cubit.updateDraft(status: values.first),
                    closeSemanticLabel: 'Fechar seleção de status',
                    label: 'Status',
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  AppCheckbox(
                    value: state.stackableWithOtherCampaigns,
                    label: 'Permite empilhamento com outras campanhas',
                    onChanged: (value) =>
                        cubit.updateDraft(stackableWithOtherCampaigns: value),
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  _DateButtonRow(state: state, cubit: cubit),
                  if (state.fieldErrors['validTo'] != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.spacing4),
                    Text(
                      state.fieldErrors['validTo']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spacing12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      label: state.isEditing
                          ? 'Salvar alterações'
                          : 'Criar campanha',
                      leadingIcon: Icons.save_outlined,
                      isLoading: state.isBusy,
                      onPressed: state.isBusy ? null : cubit.submit,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing24),
                  SizedBox(
                    height: 420,
                    child: _CampaignTable(state: state, cubit: cubit),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }
}

class _DateButtonRow extends StatelessWidget {
  const _DateButtonRow({required this.state, required this.cubit});

  final PromotionalCampaignState state;
  final PromotionalCampaignCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppButton(
            label: 'Início: ${_label(state.validFrom)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final picked = await _pickDate(context, state.validFrom);
              if (picked != null) cubit.updateDraft(validFrom: picked);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.spacing12),
        Expanded(
          child: AppButton(
            label: 'Fim: ${_label(state.validTo)}',
            leadingIcon: Icons.event_outlined,
            variant: AppButtonVariant.secondary,
            onPressed: () async {
              final picked = await _pickDate(context, state.validTo);
              if (picked != null) cubit.updateDraft(validTo: picked);
            },
          ),
        ),
      ],
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final base = initial ?? DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(base.year - 3),
      lastDate: DateTime(base.year + 5),
    );
  }

  String _label(DateTime? date) {
    if (date == null) return 'sem data';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _CampaignTable extends StatelessWidget {
  const _CampaignTable({required this.state, required this.cubit});

  final PromotionalCampaignState state;
  final PromotionalCampaignCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == PromotionalCampaignLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == PromotionalCampaignLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar as campanhas',
        message: state.failureMessage ?? 'Tente novamente em breve.',
      );
    }
    if (state.campaigns.isEmpty) {
      return const AppEmptyState(
        icon: Icons.local_offer_outlined,
        title: 'Nenhuma campanha cadastrada',
        description:
            'Cadastre campanhas com vigência, prioridade e escopo para rastrear a origem do desconto.',
      );
    }

    return SingleChildScrollView(
      child: AppDataTable<PromotionalCampaign>(
        status: AppDataTableStatus.idle,
        rows: state.campaigns,
        rowIdBuilder: (item) => item.id,
        mobileCardTitleBuilder: (context, item) => Text(item.name),
        columns: <AppDataColumn<PromotionalCampaign>>[
          AppDataColumn(
            label: 'Campanha',
            cellBuilder: (context, item) => Text(item.name),
          ),
          AppDataColumn(
            label: 'Segmento',
            cellBuilder: (context, item) => Text(item.customerSegment),
          ),
          AppDataColumn(
            label: 'Prioridade',
            cellBuilder: (context, item) => Text(item.priority.toString()),
          ),
          AppDataColumn(
            label: 'Empilhável',
            cellBuilder: (context, item) =>
                Text(item.stackableWithOtherCampaigns ? 'Sim' : 'Não'),
          ),
          AppDataColumn(
            label: 'Status',
            cellBuilder: (context, item) => Text(item.status.name),
          ),
        ],
        rowActions: <AppDataTableAction<PromotionalCampaign>>[
          AppDataTableAction<PromotionalCampaign>(
            icon: Icons.edit_outlined,
            semanticLabel: 'Editar campanha',
            onPressed: cubit.startEdit,
          ),
        ],
      ),
    );
  }
}
