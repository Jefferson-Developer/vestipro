import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../bloc/customer_import_bloc.dart';
import '../bloc/customer_import_event.dart';
import '../bloc/customer_import_state.dart';
import '../widgets/customer_import_mapping_step.dart';
import '../widgets/customer_import_progress_report_step.dart';
import '../widgets/customer_import_upload_step.dart';

const List<String> _kCustomerImportStepLabels = <String>[
  'Enviar planilha',
  'Mapear colunas',
  'Progresso e relatório',
];

/// Entry point for the customer-import wizard (TASK-167) — upload, column
/// mapping (with saved templates) and async job progress/report, gated by
/// `Capability.customerImport` (OWNER/ADMIN/SALES_MANAGER only, same
/// "gestor" scope `tasks.md` describes for this feature).
class CustomerImportPage extends StatelessWidget {
  const CustomerImportPage({
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
  final CustomerImportBloc Function() createBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.customerImport,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CustomerImportBloc>(
          create: (_) => createBloc()
            ..add(
              CustomerImportStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            ),
          child: const _CustomerImportView(),
        );
      },
    );
  }
}

class _CustomerImportView extends StatelessWidget {
  const _CustomerImportView();

  Widget _stepView(CustomerImportStep step) {
    return switch (step) {
      CustomerImportStep.upload => const CustomerImportUploadStep(),
      CustomerImportStep.mapping => const CustomerImportMappingStep(),
      CustomerImportStep.progress => const CustomerImportProgressReportStep(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Importar clientes')),
      body: BlocListener<CustomerImportBloc, CustomerImportState>(
        listenWhen: (previous, current) =>
            previous.submitStatus != current.submitStatus,
        listener: (context, state) {
          if (state.submitStatus == CustomerImportSubmitStatus.failure &&
              state.submitFailure != null) {
            AppSnackbar.show(
              context,
              message: state.submitFailure!.message,
              variant: AppSnackbarVariant.error,
            );
          }
        },
        child: SafeArea(
          child: BlocBuilder<CustomerImportBloc, CustomerImportState>(
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
                          stepLabels: _kCustomerImportStepLabels,
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

  final CustomerImportState state;

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case CustomerImportStep.upload:
        return const SizedBox.shrink();
      case CustomerImportStep.mapping:
        final isSubmitting =
            state.submitStatus == CustomerImportSubmitStatus.submitting;
        return Row(
          children: <Widget>[
            Expanded(
              child: AppButton(
                label: 'Escolher outro arquivo',
                variant: AppButtonVariant.secondary,
                isDisabled: isSubmitting,
                onPressed: () => context.read<CustomerImportBloc>().add(
                  const CustomerImportRestarted(),
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
                    : () => context.read<CustomerImportBloc>().add(
                        const CustomerImportSubmitRequested(),
                      ),
              ),
            ),
          ],
        );
      case CustomerImportStep.progress:
        return AppButton(
          label: 'Nova importação',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.read<CustomerImportBloc>().add(
            const CustomerImportRestarted(),
          ),
        );
    }
  }
}
