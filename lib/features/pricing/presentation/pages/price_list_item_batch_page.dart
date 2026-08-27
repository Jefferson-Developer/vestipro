import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/price_list_item.dart';
import '../cubit/price_list_item_batch_cubit.dart';
import '../cubit/price_list_item_batch_state.dart';

class PriceListItemBatchPage extends StatelessWidget {
  const PriceListItemBatchPage({
    required this.organizationId,
    required this.companyId,
    required this.priceListId,
    required this.userId,
    required this.permissionService,
    required this.createCubit,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String priceListId;
  final String userId;
  final PermissionService permissionService;
  final PriceListItemBatchCubit Function() createCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.priceListManage,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<PriceListItemBatchCubit>(
          create: (_) {
            final cubit = createCubit();
            unawaited(
              cubit.load(
                organizationId: organizationId,
                companyId: companyId,
                priceListId: priceListId,
                userId: userId,
              ),
            );
            return cubit;
          },
          child: const _PriceListItemBatchView(),
        );
      },
    );
  }
}

class _PriceListItemBatchView extends StatefulWidget {
  const _PriceListItemBatchView();

  @override
  State<_PriceListItemBatchView> createState() =>
      _PriceListItemBatchViewState();
}

class _PriceListItemBatchViewState extends State<_PriceListItemBatchView> {
  final _productIdController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _variantExceptionsController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    _basePriceController.dispose();
    _variantExceptionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PriceListItemBatchCubit, PriceListItemBatchState>(
      listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus ||
          previous.productId != current.productId ||
          previous.basePriceInput != current.basePriceInput ||
          previous.variantExceptionsInput != current.variantExceptionsInput,
      listener: (context, state) async {
        _sync(_productIdController, state.productId);
        _sync(_basePriceController, state.basePriceInput);
        _sync(_variantExceptionsController, state.variantExceptionsInput);
        if (state.saveStatus == PriceListItemBatchSaveStatus.success) {
          AppSnackbar.show(
            context,
            message: 'Preços salvos na tabela.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.saveStatus == PriceListItemBatchSaveStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Não foi possível salvar.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.saveStatus == PriceListItemBatchSaveStatus.overwriteWarning) {
          final confirmed = await AppConfirmationDialog.show(
            context: context,
            title: 'Sobrescrever preços existentes',
            message:
                'Já existem preços para este produto ou variante. Confirme para sobrescrever conscientemente.',
            confirmLabel: 'Sobrescrever',
          );
          if (!context.mounted || !confirmed) return;
          await context.read<PriceListItemBatchCubit>().submit(
            confirmOverwrite: true,
          );
        }
      },
      builder: (context, state) {
        _sync(_productIdController, state.productId);
        _sync(_basePriceController, state.basePriceInput);
        _sync(_variantExceptionsController, state.variantExceptionsInput);
        final cubit = context.read<PriceListItemBatchCubit>();
        return Scaffold(
          body: AppAdminPageLayout(
            title: 'Preços por produto e variante',
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _productIdController,
                  label: 'Produto',
                  semanticLabel: 'Produto',
                  isRequired: true,
                  errorText:
                      state.fieldErrors['items[0].productId'] ??
                      state.fieldErrors['productId'],
                  onChanged: (value) => cubit.updateForm(productId: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _basePriceController,
                  label: 'Preço base do produto',
                  hintText: '189,90',
                  semanticLabel: 'Preço base do produto',
                  isRequired: true,
                  errorText: state.fieldErrors['items[0].price'],
                  onChanged: (value) => cubit.updateForm(basePriceInput: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                AppTextField(
                  controller: _variantExceptionsController,
                  label: 'Exceções por variante',
                  hintText: 'variant-azul-pp=199,90',
                  semanticLabel: 'Exceções por variante',
                  maxLines: 6,
                  errorText: state.fieldErrors['items[1].price'],
                  onChanged: (value) =>
                      cubit.updateForm(variantExceptionsInput: value),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Salvar preços',
                    leadingIcon: Icons.save_outlined,
                    isLoading: state.isBusy,
                    onPressed: state.isBusy ? null : () => cubit.submit(),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing24),
                Expanded(child: _ItemsTable(state: state)),
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

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.state});

  final PriceListItemBatchState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadStatus == PriceListItemBatchLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.loadStatus == PriceListItemBatchLoadStatus.failure) {
      return AppErrorState(
        title: 'Não foi possível carregar os preços',
        message: state.failure?.message ?? 'Tente novamente em breve.',
      );
    }
    if (state.items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.sell_outlined,
        title: 'Nenhum preço cadastrado',
        description:
            'Cadastre um preço base por produto e exceções apenas quando uma variante realmente divergir.',
      );
    }

    final sorted = List<PriceListItem>.of(state.items)
      ..sort((a, b) {
        final byProduct = a.productId.compareTo(b.productId);
        if (byProduct != 0) return byProduct;
        return (a.variantId ?? '').compareTo(b.variantId ?? '');
      });

    return SingleChildScrollView(
      child: AppDataTable<PriceListItem>(
        status: AppDataTableStatus.idle,
        rows: sorted,
        rowIdBuilder: (item) => item.id,
        mobileCardTitleBuilder: (context, item) => Text(item.productId),
        columns: <AppDataColumn<PriceListItem>>[
          AppDataColumn(
            label: 'Produto',
            cellBuilder: (context, item) => Text(item.productId),
          ),
          AppDataColumn(
            label: 'Variante',
            cellBuilder: (context, item) =>
                Text(item.variantId ?? 'Fallback do produto'),
          ),
          AppDataColumn(
            label: 'Preço',
            cellBuilder: (context, item) => Text(item.price.toStringAsFixed(2)),
          ),
        ],
      ),
    );
  }
}
