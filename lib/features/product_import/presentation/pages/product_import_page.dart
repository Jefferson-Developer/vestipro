import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../bloc/product_import_bloc.dart';
import '../bloc/product_import_event.dart';
import '../bloc/product_import_state.dart';
import '../widgets/product_import_mapping_step.dart';
import '../widgets/product_import_progress_report_step.dart';
import '../widgets/product_import_upload_step.dart';

const List<String> _kProductImportStepLabels = <String>[
  'Enviar planilha',
  'Mapear colunas e grade',
  'Progresso e relatório',
];

/// Entry point for the product-import wizard (TASK-168) — upload, column
/// mapping (size grid, categoria/coleção/cor e pacote de imagens opcional) e
/// progresso/relatório do job assíncrono, gated by `Capability.productImport`
/// (OWNER/ADMIN only — importação em massa de catálogo é uma ação de gestão
/// de catálogo, mesmo escopo de `Capability.catalogManage`).
class ProductImportPage extends StatelessWidget {
  const ProductImportPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final ProductImportBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.productImport,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<ProductImportBloc>(
          create: (_) => createBloc()
            ..add(
              ProductImportStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            ),
          child: const _ProductImportView(),
        );
      },
    );
  }
}

class _ProductImportView extends StatelessWidget {
  const _ProductImportView();

  Widget _stepView(ProductImportStep step) {
    return switch (step) {
      ProductImportStep.upload => const ProductImportUploadStep(),
      ProductImportStep.mapping => const ProductImportMappingStep(),
      ProductImportStep.progress => const ProductImportProgressReportStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Importar produtos')),
      body: BlocListener<ProductImportBloc, ProductImportState>(
        listenWhen: (previous, current) =>
            previous.submitStatus != current.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == ProductImportSubmitStatus.failure &&
              state.submitFailure != null) {
            AppSnackbar.show(
              context,
              message: state.submitFailure!.message,
              variant: AppSnackbarVariant.error,
            );
          }
        },
        child: SafeArea(
          child: BlocBuilder<ProductImportBloc, ProductImportState>(
            builder: (context, state) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.spacing24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        AppWizardStepper(
                          currentStep: state.step.index + 1,
                          stepLabels: _kProductImportStepLabels,
                        ),
                        const SizedBox(height: AppSpacing.spacing32),
                        _stepView(state.step),
                        const SizedBox(height: AppSpacing.spacing32),
                        _StepActions(state: state),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StepActions extends StatelessWidget {
  const _StepActions({required this.state});

  final ProductImportState state;

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case ProductImportStep.upload:
        return const SizedBox.shrink();
      case ProductImportStep.mapping:
        final isSubmitting =
            state.submitStatus == ProductImportSubmitStatus.submitting;
        return Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Escolher outro arquivo',
                variant: AppButtonVariant.secondary,
                isDisabled: isSubmitting,
                onPressed: () => context.read<ProductImportBloc>().add(
                  const ProductImportRestarted(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: AppButton(
                label: 'Iniciar importação',
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () => context.read<ProductImportBloc>().add(
                        const ProductImportSubmitRequested(),
                      ),
              ),
            ),
          ],
        );
      case ProductImportStep.progress:
        return AppButton(
          label: 'Nova importação',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.read<ProductImportBloc>().add(
            const ProductImportRestarted(),
          ),
        );
    }
  }
}
