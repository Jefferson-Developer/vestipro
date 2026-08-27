import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/payment_term.dart';
import '../../domain/value_objects/payment_term_status.dart';
import '../cubit/payment_terms_cubit.dart';
import '../cubit/payment_terms_state.dart';

class PaymentTermsPage extends StatelessWidget {
  const PaymentTermsPage({
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
  final PaymentTermsCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.priceListManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<PaymentTermsCubit>(
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
          child: const _PaymentTermsView(),
        );
      },
    );
  }
}

class _PaymentTermsView extends StatefulWidget {
  const _PaymentTermsView();

  @override
  State<_PaymentTermsView> createState() => _PaymentTermsViewState();
}

class _PaymentTermsViewState extends State<_PaymentTermsView> {
  final _nameController = TextEditingController();
  final _installmentsController = TextEditingController();
  final _priceListIdsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _installmentsController.dispose();
    _priceListIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentTermsCubit, PaymentTermsState>(
      listenWhen: (previous, current) =>
          previous.name != current.name ||
          previous.installmentsInput != current.installmentsInput ||
          previous.priceListIdsInput != current.priceListIdsInput ||
          previous.saveStatus != current.saveStatus,
      listener: (context, state) {
        _sync(_nameController, state.name);
        _sync(_installmentsController, state.installmentsInput);
        _sync(_priceListIdsController, state.priceListIdsInput);
        if (state.saveStatus == PaymentTermsSaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Condição de pagamento salva.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == PaymentTermsSaveStatus.failure &&
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
        _sync(_installmentsController, state.installmentsInput);
        _sync(_priceListIdsController, state.priceListIdsInput);
        final cubit = context.read<PaymentTermsCubit>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Condições de pagamento',
            actions: <Widget>[
              AppButton(
                label: state.isEditing ? 'Nova condição' : 'Limpar formulário',
                leadingIcon: Icons.add_card_outlined,
                onPressed: state.isBusy ? null : cubit.startCreate,
              ),
            ],
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _nameController,
                  label: 'Nome',
                  semanticLabel: 'Nome da condição de pagamento',
                  isRequired: true,
                  errorText: state.fieldErrors['name'],
                  onChanged: (value) => cubit.updateDraft(name: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppDropdown<PaymentTermStatus>(
                  options: const <AppDropdownOption<PaymentTermStatus>>[
                    AppDropdownOption(
                      value: PaymentTermStatus.active,
                      label: 'Ativa',
                    ),
                    AppDropdownOption(
                      value: PaymentTermStatus.inactive,
                      label: 'Inativa',
                    ),
                  ],
                  selectedValues: <PaymentTermStatus>{state.status},
                  onChanged: (values) =>
                      cubit.updateDraft(status: values.first),
                  closeSemanticLabel: 'Fechar seleção de status',
                  label: 'Status',
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _priceListIdsController,
                  label: 'Tabelas de preço permitidas',
                  semanticLabel: 'Tabelas de preço permitidas',
                  hintText: 'price-list-varejo, price-list-atacado',
                  errorText: state.fieldErrors['priceListIds'],
                  onChanged: (value) =>
                      cubit.updateDraft(priceListIdsInput: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _installmentsController,
                  label: 'Parcelas (%:dias)',
                  semanticLabel: 'Parcelas da condição de pagamento',
                  hintText: '50:30\n50:60',
                  maxLines: 5,
                  isRequired: true,
                  errorText: state.fieldErrors['installments'],
                  onChanged: (value) =>
                      cubit.updateDraft(installmentsInput: value),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  'Total dos percentuais: ${state.installmentsTotal.toStringAsFixed(0)}%',
                  key: const ValueKey<String>('payment_term_total_label'),
                ),
                if (state.installmentsInput.trim().isNotEmpty &&
                    (state.installmentsTotal - 100).abs() > 0.0001)
                  Text(
                    'A soma deve totalizar 100% para salvar.',
                    key: const ValueKey<String>('payment_term_total_error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: AppSpacing.spacing12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: state.isEditing
                        ? 'Salvar alterações'
                        : 'Criar condição',
                    leadingIcon: Icons.save_outlined,
                    isLoading: state.isBusy,
                    onPressed: state.isBusy ? null : () => cubit.submit(),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                Expanded(
                  child: _PaymentTermsTable(state: state, cubit: cubit),
                ),
              ],
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

class _PaymentTermsTable extends StatelessWidget {
  const _PaymentTermsTable({required this.state, required this.cubit});

  final PaymentTermsState state;
  final PaymentTermsCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == PaymentTermsLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == PaymentTermsLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar as condições',
        message: state.failureMessage ?? 'Tente novamente em breve.',
      );
    }
    if (state.paymentTerms.isEmpty) {
      return const AppEmptyState(
        icon: Icons.credit_card_outlined,
        title: 'Nenhuma condição cadastrada',
        description:
            'Cadastre condições com parcelas e prazo médio para liberar o fluxo comercial do pedido.',
      );
    }

    return SingleChildScrollView(
      child: AppDataTable<PaymentTerm>(
        status: AppDataTableStatus.idle,
        rows: state.paymentTerms,
        rowIdBuilder: (item) => item.id,
        mobileCardTitleBuilder: (context, item) => Text(item.name),
        columns: <AppDataColumn<PaymentTerm>>[
          AppDataColumn(
            label: 'Condição',
            cellBuilder: (context, item) => Text(item.name),
          ),
          AppDataColumn(
            label: 'Status',
            cellBuilder: (context, item) => Text(
              item.status == PaymentTermStatus.active ? 'Ativa' : 'Inativa',
            ),
          ),
          AppDataColumn(
            label: 'Prazo médio',
            cellBuilder: (context, item) =>
                Text('${item.averageTermDays.toStringAsFixed(1)} dias'),
          ),
          AppDataColumn(
            label: 'Escopo',
            cellBuilder: (context, item) => Text(
              item.priceListIds.isEmpty
                  ? 'Todas as tabelas'
                  : item.priceListIds.join(', '),
            ),
          ),
        ],
        rowActions: <AppDataTableAction<PaymentTerm>>[
          AppDataTableAction<PaymentTerm>(
            icon: Icons.edit_outlined,
            semanticLabel: 'Editar condição',
            onPressed: cubit.startEdit,
          ),
        ],
      ),
    );
  }
}
