import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../approach_suggestion/approach_suggestion.dart';
import '../../../credit/credit.dart';
import '../../../crm/crm.dart';
import '../../../product_recommendations/product_recommendations.dart';
import '../../../receivables/receivables.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/value_objects/customer_health_score_band.dart';
import '../../domain/value_objects/customer_status.dart';
import '../../domain/value_objects/customer_sync_status.dart';
import '../../domain/value_objects/customer_type.dart';
import '../bloc/customer_detail_bloc.dart';
import '../bloc/customer_detail_event.dart';
import '../bloc/customer_detail_state.dart';

class CustomerDetailPage extends StatelessWidget {
  const CustomerDetailPage({
    required this.organizationId,
    required this.customerId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.createApproachSuggestionCubit,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
    this.createProductRecommendationsBloc,
    super.key,
  });

  final String organizationId;
  final String customerId;
  final String userId;
  final PermissionService permissionService;
  final CustomerDetailBloc Function() createBloc;

  /// Factory for TASK-187's "Sugerir abordagem" sheet cubit — a fresh
  /// instance is created every time the sheet opens (mirrors
  /// `RepresentativeDashboardPage.createWalletSummaryCubit`, TASK-186).
  final ApproachSuggestionCubit Function() createApproachSuggestionCubit;

  /// Factory for TASK-212's credit section cubit (`CustomerCreditPanel`) —
  /// same "fresh instance per screen" shape as [createApproachSuggestionCubit].
  final CustomerCreditCubit Function() createCreditPanelCubit;

  /// Factory for TASK-213's billing section cubit (`CustomerBillingPanel`) —
  /// same "fresh instance per screen" shape as [createCreditPanelCubit].
  final CustomerBillingCubit Function() createBillingPanelCubit;

  /// Factory for TASK-190's "Recomendações" sheet bloc — same
  /// "fresh instance per sheet open" shape as
  /// [createApproachSuggestionCubit]. Optional: when `null`, the
  /// "Recomendações" quick action is not shown at all (keeps every existing
  /// caller/test of this page working unchanged without the feature).
  final ProductRecommendationsBloc Function()? createProductRecommendationsBloc;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.customerView,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return BlocProvider<CustomerDetailBloc>(
          create: (_) => createBloc()
            ..add(
              CustomerDetailStarted(
                organizationId: organizationId,
                customerId: customerId,
                userId: userId,
              ),
            ),
          child: CustomerDetailView(
            organizationId: organizationId,
            userId: userId,
            permissionService: permissionService,
            createApproachSuggestionCubit: createApproachSuggestionCubit,
            createCreditPanelCubit: createCreditPanelCubit,
            createBillingPanelCubit: createBillingPanelCubit,
            createProductRecommendationsBloc: createProductRecommendationsBloc,
          ),
        );
      },
    );
  }
}

@visibleForTesting
class CustomerDetailView extends StatelessWidget {
  const CustomerDetailView({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createApproachSuggestionCubit,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
    this.createProductRecommendationsBloc,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ApproachSuggestionCubit Function() createApproachSuggestionCubit;
  final CustomerCreditCubit Function() createCreditPanelCubit;
  final CustomerBillingCubit Function() createBillingPanelCubit;
  final ProductRecommendationsBloc Function()? createProductRecommendationsBloc;

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomerDetailBloc, CustomerDetailState>(
      listenWhen: (previous, current) =>
          previous.activitySubmissionStatus != current.activitySubmissionStatus,
      listener: (context, state) {
        switch (state.activitySubmissionStatus) {
          case CustomerDetailActivitySubmissionStatus.success:
            AppSnackbar.show(
              context,
              message: 'Atividade registrada e salva offline.',
              variant: AppSnackbarVariant.success,
            );
            context.read<CustomerDetailBloc>().add(
              const CustomerDetailActivitySubmissionAcknowledged(),
            );
          case CustomerDetailActivitySubmissionStatus.failure:
            AppSnackbar.show(
              context,
              message:
                  state.activitySubmissionFailure?.message ??
                  'Nao foi possivel registrar a atividade.',
              variant: AppSnackbarVariant.error,
            );
            context.read<CustomerDetailBloc>().add(
              const CustomerDetailActivitySubmissionAcknowledged(),
            );
          case CustomerDetailActivitySubmissionStatus.idle:
          case CustomerDetailActivitySubmissionStatus.submitting:
            break;
        }
      },
      child: BlocBuilder<CustomerDetailBloc, CustomerDetailState>(
        builder: (context, state) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing24),
              child: _CustomerDetailBody(
                state: state,
                organizationId: organizationId,
                userId: userId,
                permissionService: permissionService,
                createApproachSuggestionCubit: createApproachSuggestionCubit,
                createCreditPanelCubit: createCreditPanelCubit,
                createBillingPanelCubit: createBillingPanelCubit,
                createProductRecommendationsBloc:
                    createProductRecommendationsBloc,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CustomerDetailBody extends StatelessWidget {
  const _CustomerDetailBody({
    required this.state,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createApproachSuggestionCubit,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
    this.createProductRecommendationsBloc,
  });

  final CustomerDetailState state;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ApproachSuggestionCubit Function() createApproachSuggestionCubit;
  final CustomerCreditCubit Function() createCreditPanelCubit;
  final CustomerBillingCubit Function() createBillingPanelCubit;
  final ProductRecommendationsBloc Function()? createProductRecommendationsBloc;

  @override
  Widget build(BuildContext context) {
    if (state.status == CustomerDetailLoadStatus.failure) {
      return AppErrorState(
        title: 'Nao foi possivel carregar o cliente',
        message: state.failure?.message ?? 'Tente novamente em breve.',
        retryLabel: 'Tentar novamente',
        onRetry: () => context.read<CustomerDetailBloc>().add(
          const CustomerDetailRetried(),
        ),
      );
    }
    if (state.isLoading || state.customer == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return _CustomerDetailContent(
      customer: state.customer!,
      nextBestAction: state.nextBestAction,
      organizationId: organizationId,
      userId: userId,
      permissionService: permissionService,
      createApproachSuggestionCubit: createApproachSuggestionCubit,
      createCreditPanelCubit: createCreditPanelCubit,
      createBillingPanelCubit: createBillingPanelCubit,
      createProductRecommendationsBloc: createProductRecommendationsBloc,
    );
  }
}

class _CustomerDetailContent extends StatelessWidget {
  const _CustomerDetailContent({
    required this.customer,
    required this.nextBestAction,
    required this.organizationId,
    required this.userId,
    required this.createApproachSuggestionCubit,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
    required this.permissionService,
    this.createProductRecommendationsBloc,
  });

  final Customer customer;
  final NextBestAction? nextBestAction;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ApproachSuggestionCubit Function() createApproachSuggestionCubit;
  final CustomerCreditCubit Function() createCreditPanelCubit;
  final CustomerBillingCubit Function() createBillingPanelCubit;
  final ProductRecommendationsBloc Function()? createProductRecommendationsBloc;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        final key = switch (breakpoint) {
          AppBreakpoint.mobile => const Key('customer-detail-mobile'),
          AppBreakpoint.tablet => const Key('customer-detail-tablet'),
          AppBreakpoint.desktop ||
          AppBreakpoint.largeDesktop => const Key('customer-detail-desktop'),
        };
        final content =
            breakpoint == AppBreakpoint.desktop ||
                breakpoint == AppBreakpoint.largeDesktop
            ? _DesktopCustomerDetail(
                customer: customer,
                nextBestAction: nextBestAction,
                organizationId: organizationId,
                userId: userId,
                permissionService: permissionService,
                createApproachSuggestionCubit: createApproachSuggestionCubit,
                createCreditPanelCubit: createCreditPanelCubit,
                createBillingPanelCubit: createBillingPanelCubit,
                createProductRecommendationsBloc:
                    createProductRecommendationsBloc,
              )
            : _StackedCustomerDetail(
                customer: customer,
                nextBestAction: nextBestAction,
                organizationId: organizationId,
                userId: userId,
                permissionService: permissionService,
                createApproachSuggestionCubit: createApproachSuggestionCubit,
                createCreditPanelCubit: createCreditPanelCubit,
                createBillingPanelCubit: createBillingPanelCubit,
                createProductRecommendationsBloc:
                    createProductRecommendationsBloc,
              );

        return SingleChildScrollView(key: key, child: content);
      },
    );
  }
}

class _StackedCustomerDetail extends StatelessWidget {
  const _StackedCustomerDetail({
    required this.customer,
    required this.nextBestAction,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createApproachSuggestionCubit,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
    this.createProductRecommendationsBloc,
  });

  final Customer customer;
  final NextBestAction? nextBestAction;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ApproachSuggestionCubit Function() createApproachSuggestionCubit;
  final CustomerCreditCubit Function() createCreditPanelCubit;
  final CustomerBillingCubit Function() createBillingPanelCubit;
  final ProductRecommendationsBloc Function()? createProductRecommendationsBloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CustomerHeader(
          customer: customer,
          onRegisterActivity: () => _showRegisterActivitySheet(context),
          onSuggestApproach: () => _showApproachSuggestionSheet(
            context,
            organizationId: organizationId,
            customer: customer,
            createCubit: createApproachSuggestionCubit,
          ),
          onShowRecommendations: createProductRecommendationsBloc == null
              ? null
              : () => _showProductRecommendationsSheet(
                  context,
                  organizationId: organizationId,
                  userId: userId,
                  customer: customer,
                  createBloc: createProductRecommendationsBloc!,
                ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        _RegistrationSection(customer: customer),
        const SizedBox(height: AppSpacing.spacing16),
        _IndicatorSection(customer: customer),
        const SizedBox(height: AppSpacing.spacing16),
        _SensitiveCommercialSection(
          organizationId: organizationId,
          companyId: customer.companyId,
          customerId: customer.id,
          userId: userId,
          permissionService: permissionService,
          createCreditPanelCubit: createCreditPanelCubit,
          createBillingPanelCubit: createBillingPanelCubit,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        const _TimelineSection(),
        const SizedBox(height: AppSpacing.spacing16),
        const _OpportunitiesSection(),
        const SizedBox(height: AppSpacing.spacing16),
        const _OrderHistorySection(),
        const SizedBox(height: AppSpacing.spacing16),
        _NextBestActionSection(action: nextBestAction),
      ],
    );
  }
}

class _DesktopCustomerDetail extends StatelessWidget {
  const _DesktopCustomerDetail({
    required this.customer,
    required this.nextBestAction,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createApproachSuggestionCubit,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
    this.createProductRecommendationsBloc,
  });

  final Customer customer;
  final NextBestAction? nextBestAction;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final ApproachSuggestionCubit Function() createApproachSuggestionCubit;
  final CustomerCreditCubit Function() createCreditPanelCubit;
  final CustomerBillingCubit Function() createBillingPanelCubit;
  final ProductRecommendationsBloc Function()? createProductRecommendationsBloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CustomerHeader(
          customer: customer,
          onRegisterActivity: () => _showRegisterActivitySheet(context),
          onSuggestApproach: () => _showApproachSuggestionSheet(
            context,
            organizationId: organizationId,
            customer: customer,
            createCubit: createApproachSuggestionCubit,
          ),
          onShowRecommendations: createProductRecommendationsBloc == null
              ? null
              : () => _showProductRecommendationsSheet(
                  context,
                  organizationId: organizationId,
                  userId: userId,
                  customer: customer,
                  createBloc: createProductRecommendationsBloc!,
                ),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Column(
                children: <Widget>[
                  _RegistrationSection(customer: customer),
                  const SizedBox(height: AppSpacing.spacing16),
                  const _TimelineSection(),
                  const SizedBox(height: AppSpacing.spacing16),
                  const _OrderHistorySection(),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.spacing16),
            Expanded(
              flex: 2,
              child: Column(
                children: <Widget>[
                  _IndicatorSection(customer: customer),
                  const SizedBox(height: AppSpacing.spacing16),
                  _SensitiveCommercialSection(
                    organizationId: organizationId,
                    companyId: customer.companyId,
                    customerId: customer.id,
                    userId: userId,
                    permissionService: permissionService,
                    createCreditPanelCubit: createCreditPanelCubit,
                    createBillingPanelCubit: createBillingPanelCubit,
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  const _OpportunitiesSection(),
                  const SizedBox(height: AppSpacing.spacing16),
                  _NextBestActionSection(action: nextBestAction),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({
    required this.customer,
    required this.onRegisterActivity,
    required this.onSuggestApproach,
    this.onShowRecommendations,
  });

  final Customer customer;
  final VoidCallback onRegisterActivity;
  final VoidCallback onSuggestApproach;

  /// `null` hides the "Recomendações" quick action entirely (TASK-190,
  /// EPIC-28) — same optional-seam shape already used elsewhere on this
  /// page.
  final VoidCallback? onShowRecommendations;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppStatusBadge(
                label: _statusLabel(customer.status),
                variant: _statusVariant(customer.status),
              ),
              AppStatusBadge(
                label: _syncLabel(customer.syncStatus),
                variant: customer.syncStatus == CustomerSyncStatus.synced
                    ? AppStatusBadgeVariant.success
                    : AppStatusBadgeVariant.warning,
                icon: Icons.cloud_queue,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Text(
            customer.displayName,
            style: AppTypography.titleLarge.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            customer.document.formatted,
            style: AppTypography.bodyLarge.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          _QuickActions(
            customer: customer,
            onRegisterActivity: onRegisterActivity,
            onSuggestApproach: onSuggestApproach,
            onShowRecommendations: onShowRecommendations,
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.customer,
    required this.onRegisterActivity,
    required this.onSuggestApproach,
    this.onShowRecommendations,
  });

  final Customer customer;
  final VoidCallback onRegisterActivity;
  final VoidCallback onSuggestApproach;
  final VoidCallback? onShowRecommendations;

  @override
  Widget build(BuildContext context) {
    final phone = _preferredPhone(customer);
    final email = _preferredEmail(customer);
    return Wrap(
      spacing: AppSpacing.spacing8,
      runSpacing: AppSpacing.spacing8,
      children: <Widget>[
        if (phone != null)
          AppButton(
            label: 'Ligar',
            leadingIcon: Icons.call_outlined,
            variant: AppButtonVariant.secondary,
            semanticLabel: 'Ligar para $phone',
            onPressed: () => _showPlaceholder(
              context,
              'Ligacao ficara disponivel com a integracao de telefonia.',
            ),
          )
        else
          const _ActionUnavailable(label: 'Sem telefone'),
        if (email != null)
          AppButton(
            label: 'Mensagem',
            leadingIcon: Icons.mail_outline,
            variant: AppButtonVariant.secondary,
            semanticLabel: 'Enviar mensagem para $email',
            onPressed: () => _showPlaceholder(
              context,
              'Envio de mensagem ficara disponivel com CRM/WhatsApp.',
            ),
          )
        else
          const _ActionUnavailable(label: 'Sem e-mail'),
        AppButton(
          label: 'Atividade',
          leadingIcon: Icons.add_task_outlined,
          semanticLabel: 'Registrar atividade',
          onPressed: onRegisterActivity,
        ),
        AppButton(
          label: 'Abordagem',
          leadingIcon: Icons.auto_awesome,
          variant: AppButtonVariant.secondary,
          semanticLabel: 'Sugerir abordagem comercial com IA',
          onPressed: onSuggestApproach,
        ),
        if (onShowRecommendations != null)
          AppButton(
            label: 'Recomendações',
            leadingIcon: Icons.recommend_outlined,
            variant: AppButtonVariant.secondary,
            semanticLabel: 'Ver recomendações de produtos para este cliente',
            onPressed: onShowRecommendations,
          ),
      ],
    );
  }

  static void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Opens TASK-187's "Sugerir abordagem" sheet for [customer]. When the
/// seller taps "Usar como atividade" inside the sheet, this closes the
/// suggestion sheet and reopens the existing "Registrar atividade" sheet
/// (`_showRegisterActivitySheet`) pre-filled with the (possibly edited)
/// draft, clearly marked as IA-generated — the same rastreabilidade
/// mechanism the CRM timeline already provides for every other activity,
/// never a new persistence path invented just for this feature
/// (`tasks.md`/TASK-187: "Registrar no histórico do cliente... quando uma
/// sugestão foi usada como base de uma atividade").
Future<void> _showApproachSuggestionSheet(
  BuildContext context, {
  required String organizationId,
  required Customer customer,
  required ApproachSuggestionCubit Function() createCubit,
}) {
  return AppBottomSheet.show<void>(
    context: context,
    title: 'Sugerir abordagem',
    contentKey: const Key('approach-suggestion-sheet'),
    builder: (sheetContext) => BlocProvider<ApproachSuggestionCubit>(
      create: (_) => createCubit(),
      child: ApproachSuggestionSheet(
        organizationId: organizationId,
        companyId: customer.companyId,
        customerId: customer.id,
        customerName: customer.displayName,
        onUseAsActivity: (editedText) {
          Navigator.of(sheetContext).pop();
          unawaited(
            _showRegisterActivitySheet(
              context,
              initialType: CrmActivityType.note,
              initialDescription:
                  'Abordagem sugerida por IA (revisada pelo vendedor): $editedText',
            ),
          );
        },
      ),
    ),
  );
}

/// Opens TASK-190's "Recomendações de produtos" sheet, scoped to [customer]
/// (`ProductRecommendationScopeType.customer`) — same
/// "fresh bloc per sheet open" shape as [_showApproachSuggestionSheet].
Future<void> _showProductRecommendationsSheet(
  BuildContext context, {
  required String organizationId,
  required String userId,
  required Customer customer,
  required ProductRecommendationsBloc Function() createBloc,
}) {
  return AppBottomSheet.show<void>(
    context: context,
    title: 'Recomendações de produtos',
    contentKey: const Key('product-recommendations-sheet'),
    builder: (sheetContext) => BlocProvider<ProductRecommendationsBloc>(
      create: (_) => createBloc()
        ..add(
          ProductRecommendationsRequested(
            organizationId: organizationId,
            companyId: customer.companyId,
            userId: userId,
            scopeType: ProductRecommendationScopeType.customer,
            scopeId: customer.id,
          ),
        ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: ProductRecommendationsSection(
          title: 'Recomendado para ${customer.displayName}',
        ),
      ),
    ),
  );
}

Future<void> _showRegisterActivitySheet(
  BuildContext context, {
  CrmActivityType initialType = CrmActivityType.phoneCall,
  String? initialDescription,
}) {
  final bloc = context.read<CustomerDetailBloc>();
  return AppBottomSheet.show<void>(
    context: context,
    title: 'Registrar atividade',
    contentKey: const Key('register-crm-activity-sheet'),
    builder: (sheetContext) => BlocProvider<CustomerDetailBloc>.value(
      value: bloc,
      child: _RegisterActivitySheet(
        initialType: initialType,
        initialDescription: initialDescription,
      ),
    ),
  );
}

class _RegisterActivitySheet extends StatefulWidget {
  const _RegisterActivitySheet({
    required this.initialType,
    this.initialDescription,
  });

  final CrmActivityType initialType;
  final String? initialDescription;

  @override
  State<_RegisterActivitySheet> createState() => _RegisterActivitySheetState();
}

class _RegisterActivitySheetState extends State<_RegisterActivitySheet> {
  late final TextEditingController _descriptionController;
  late CrmActivityType _type;
  String? _descriptionError;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _descriptionError = 'Descreva a atividade realizada.');
      return;
    }
    context.read<CustomerDetailBloc>().add(
      CustomerDetailActivitySubmitted(description: description, type: _type),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppDropdown<CrmActivityType>(
          label: 'Tipo',
          isRequired: true,
          closeSemanticLabel: 'Fechar selecao de tipo',
          enableSearch: false,
          selectedValues: <CrmActivityType>{_type},
          options: CrmActivityType.values
              .map(
                (type) => AppDropdownOption<CrmActivityType>(
                  value: type,
                  label: type.label,
                ),
              )
              .toList(growable: false),
          onChanged: (values) {
            if (values.isNotEmpty) {
              setState(() => _type = values.first);
            }
          },
        ),
        const SizedBox(height: AppSpacing.spacing12),
        AppTextField(
          controller: _descriptionController,
          label: 'Descricao',
          hintText: 'Ex.: Ligacao sobre reposicao da colecao',
          isRequired: true,
          maxLines: 3,
          errorText: _descriptionError,
          semanticLabel: 'Descricao da atividade CRM',
          onChanged: (_) {
            if (_descriptionError != null) {
              setState(() => _descriptionError = null);
            }
          },
        ),
        const SizedBox(height: AppSpacing.spacing16),
        AppButton(
          label: 'Registrar atividade',
          leadingIcon: Icons.add_task_outlined,
          expand: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _ActionUnavailable extends StatelessWidget {
  const _ActionUnavailable({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.spacing48),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing12,
      ),
      decoration: BoxDecoration(
        color: colors.disabled.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: AppIconSizes.md,
            color: colors.outline,
          ),
          const SizedBox(width: AppSpacing.spacing8),
          Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: colors.outline),
          ),
        ],
      ),
    );
  }
}

class _RegistrationSection extends StatelessWidget {
  const _RegistrationSection({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Dados cadastrais',
      icon: Icons.badge_outlined,
      children: <Widget>[
        _InfoGrid(
          items: <_InfoItem>[
            _InfoItem('Tipo', _customerTypeLabel(customer.type)),
            _InfoItem('Razao social', customer.legalName),
            _InfoItem('Nome fantasia', customer.tradeName),
            _InfoItem('Nome completo', customer.fullName),
            _InfoItem('Inscricao estadual', customer.stateRegistration),
            _InfoItem('E-mail principal', customer.primaryEmail),
            _InfoItem('Telefone principal', customer.primaryPhone),
            _InfoItem('Classificacao', customer.classification),
            _InfoItem('Potencial', customer.potential),
            _InfoItem('Segmento', customer.segment),
            _InfoItem('Origem', customer.originChannel),
            _InfoItem('Vendedor responsavel', customer.responsibleSellerId),
            _InfoItem('Cadastrado em', _dateLabel(customer.registeredAt)),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing16),
        _SubsectionTitle(
          title: 'Enderecos',
          trailing: '${customer.addresses.length}',
        ),
        const SizedBox(height: AppSpacing.spacing8),
        if (customer.addresses.isEmpty)
          const _InlineEmpty(
            text: 'Nenhum endereco cadastrado para este cliente.',
          )
        else
          _AddressList(addresses: customer.addresses),
        const SizedBox(height: AppSpacing.spacing16),
        _SubsectionTitle(
          title: 'Contatos',
          trailing: '${customer.contacts.length}',
        ),
        const SizedBox(height: AppSpacing.spacing8),
        if (customer.contacts.isEmpty)
          const _InlineEmpty(
            text: 'Nenhum contato cadastrado para este cliente.',
          )
        else
          _ContactList(contacts: customer.contacts),
      ],
    );
  }
}

class _IndicatorSection extends StatelessWidget {
  const _IndicatorSection({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final hasScores = customer.hasCalculatedScores;
    final healthScore = customer.healthScore;
    final healthScoreBand = customer.healthScoreBand;
    return _SectionCard(
      title: 'Indicadores e health score',
      icon: Icons.monitor_heart_outlined,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.spacing8,
          runSpacing: AppSpacing.spacing8,
          children: <Widget>[
            AppStatusBadge(
              label: _lastPurchaseLabel(customer.lastPurchaseAt),
              variant: AppStatusBadgeVariant.neutral,
              icon: Icons.shopping_bag_outlined,
            ),
            AppStatusBadge(
              label: customer.potential?.trim().isEmpty ?? true
                  ? 'Potencial nao informado'
                  : 'Potencial ${customer.potential}',
              variant: AppStatusBadgeVariant.info,
              icon: Icons.trending_up,
            ),
            if (customer.commercialScore != null)
              AppStatusBadge(
                label: 'Score comercial ${customer.commercialScore}',
                variant: AppStatusBadgeVariant.info,
                icon: Icons.speed_outlined,
              ),
            if (healthScore != null && healthScoreBand != null)
              AppStatusBadge(
                label: 'Health $healthScore - ${healthScoreBand.label}',
                variant: _healthBandVariant(healthScoreBand),
                icon: Icons.favorite_border,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing12),
        if (hasScores)
          _ScoreSnapshot(customer: customer)
        else
          const _InlineEmpty(
            text: 'Score ainda nao calculado para este cliente.',
          ),
      ],
    );
  }
}

class _ScoreSnapshot extends StatelessWidget {
  const _ScoreSnapshot({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Formula ${customer.scoreFormulaVersion}',
          style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          '${customer.scoreDataCoverage!.label} - atualizado ${_dateLabel(customer.scoreUpdatedAt!)}',
          style: AppTypography.bodySmall.copyWith(color: colors.outline),
        ),
      ],
    );
  }
}

class _SensitiveCommercialSection extends StatelessWidget {
  const _SensitiveCommercialSection({
    required this.organizationId,
    required this.companyId,
    required this.customerId,
    required this.userId,
    required this.permissionService,
    required this.createCreditPanelCubit,
    required this.createBillingPanelCubit,
  });

  final String organizationId;
  final String companyId;
  final String customerId;
  final String userId;
  final PermissionService permissionService;
  final CustomerCreditCubit Function() createCreditPanelCubit;
  final CustomerBillingCubit Function() createBillingPanelCubit;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.reportViewSensitive,
      placeholderBuilder: (_) => const _SectionCard(
        title: 'Indicadores comerciais sensiveis',
        icon: Icons.lock_outline,
        children: <Widget>[
          _InlineEmpty(text: 'Validando permissao para dados sensiveis.'),
        ],
      ),
      builder: (context, granted) {
        if (!granted) {
          return const _SectionCard(
            title: 'Indicadores comerciais sensiveis',
            icon: Icons.lock_outline,
            children: <Widget>[
              _InlineEmpty(
                text:
                    'Sem permissao para ver margem, credito ou dados financeiros.',
              ),
            ],
          );
        }
        return _SectionCard(
          title: 'Indicadores comerciais sensiveis',
          icon: Icons.insights_outlined,
          children: <Widget>[
            const _ComingSoonPanel(
              title: 'Margem em breve',
              description: 'Nao disponivel ate politicas comerciais existirem.',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            CustomerCreditPanel(
              organizationId: organizationId,
              companyId: companyId,
              customerId: customerId,
              userId: userId,
              permissionService: permissionService,
              createCubit: createCreditPanelCubit,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              'Situacao financeira',
              style: AppTypography.titleMedium.copyWith(
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            CustomerBillingPanel(
              organizationId: organizationId,
              customerId: customerId,
              userId: userId,
              permissionService: permissionService,
              createCubit: createBillingPanelCubit,
            ),
          ],
        );
      },
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerDetailBloc, CustomerDetailState>(
      builder: (context, state) {
        final children = switch (state.timelineStatus) {
          CustomerDetailTimelineStatus.initial ||
          CustomerDetailTimelineStatus.loading => const <Widget>[
            Center(child: CircularProgressIndicator()),
          ],
          CustomerDetailTimelineStatus.failure => <Widget>[
            AppErrorState(
              title: 'Nao foi possivel carregar a timeline',
              message:
                  state.timelineFailure?.message ?? 'Tente novamente em breve.',
              retryLabel: 'Tentar novamente',
              onRetry: () => context.read<CustomerDetailBloc>().add(
                const CustomerDetailTimelineRetried(),
              ),
            ),
          ],
          CustomerDetailTimelineStatus.ready ||
          CustomerDetailTimelineStatus.loadingMore => <Widget>[
            CrmActivityTimeline(
              activities: state.activities,
              hasMore: state.activitiesHasMore,
              isLoadingMore: state.isLoadingMoreActivities,
              onLoadMore: () => context.read<CustomerDetailBloc>().add(
                const CustomerDetailTimelineLoadMoreRequested(),
              ),
            ),
          ],
        };
        return _SectionCard(
          title: 'Timeline de atividades',
          icon: Icons.timeline_outlined,
          children: children,
        );
      },
    );
  }
}

class _OpportunitiesSection extends StatelessWidget {
  const _OpportunitiesSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Oportunidades abertas',
      icon: Icons.flag_outlined,
      children: <Widget>[
        _ComingSoonPanel(
          title: 'Oportunidades em breve',
          description:
              'Nao disponivel ate leads, oportunidades e funil comercial serem implementados.',
          icon: Icons.account_tree_outlined,
        ),
      ],
    );
  }
}

class _OrderHistorySection extends StatelessWidget {
  const _OrderHistorySection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Historico de pedidos',
      icon: Icons.receipt_long_outlined,
      children: <Widget>[
        _ComingSoonPanel(
          title: 'Pedidos em breve',
          description:
              'Historico de pedidos estara disponivel quando o EPIC-13 for implementado.',
          icon: Icons.shopping_cart_outlined,
        ),
      ],
    );
  }
}

class _NextBestActionSection extends StatelessWidget {
  const _NextBestActionSection({required this.action});

  final NextBestAction? action;

  @override
  Widget build(BuildContext context) {
    final recommendation = action;
    return _SectionCard(
      title: 'Proxima melhor acao',
      icon: Icons.auto_awesome_outlined,
      children: recommendation == null
          ? const <Widget>[
              _InlineEmpty(text: 'Nenhuma recomendacao prioritaria agora.'),
            ]
          : <Widget>[
              NextBestActionCard(
                action: recommendation,
                onPressed: () => _handleNextBestAction(context, recommendation),
              ),
            ],
    );
  }
}

Future<void> _handleNextBestAction(
  BuildContext context,
  NextBestAction action,
) {
  final suggestedActivityType = action.suggestedActivityType;
  if (suggestedActivityType != null) {
    return _showRegisterActivitySheet(
      context,
      initialType: suggestedActivityType,
      initialDescription:
          'Acao sugerida: ${action.suggestedAction}. Motivo: ${action.reason}',
    );
  }

  AppSnackbar.show(
    context,
    message: 'Abra Tarefas e follow-ups para concluir ou reagendar.',
    variant: AppSnackbarVariant.info,
  );
  return Future<void>.value();
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          mainAxisSpacing: AppSpacing.spacing12,
          crossAxisSpacing: AppSpacing.spacing12,
          mainAxisExtent: AppSpacing.spacing64 + AppSpacing.spacing24,
          children: <Widget>[
            for (final item in items)
              _InfoTile(label: item.label, value: item.value),
          ],
        );
      },
    );
  }
}

class _InfoItem {
  const _InfoItem(this.label, this.value);

  final String label;
  final String? value;
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedValue = value?.trim().isEmpty ?? true
        ? 'Nao informado'
        : value!.trim();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelMedium.copyWith(color: colors.outline),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Text(
            resolvedValue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _AddressList extends StatelessWidget {
  const _AddressList({required this.addresses});

  final List<CustomerAddress> addresses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final address in addresses) ...<Widget>[
          _CompactItem(
            title: address.summary,
            subtitle:
                '${address.type.label}${address.isPrimary ? ' principal' : ''} - CEP ${address.zipCode.formatted}',
            icon: Icons.location_on_outlined,
          ),
          if (address != addresses.last)
            const SizedBox(height: AppSpacing.spacing8),
        ],
      ],
    );
  }
}

class _ContactList extends StatelessWidget {
  const _ContactList({required this.contacts});

  final List<CustomerContact> contacts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (final contact in contacts) ...<Widget>[
          _CompactItem(
            title: contact.name,
            subtitle: _contactSubtitle(contact),
            icon: Icons.person_outline,
          ),
          if (contact != contacts.last)
            const SizedBox(height: AppSpacing.spacing8),
        ],
      ],
    );
  }

  String _contactSubtitle(CustomerContact contact) {
    final details = <String>[
      contact.type.label,
      if (contact.role?.trim().isNotEmpty ?? false) contact.role!.trim(),
      if (contact.phone?.trim().isNotEmpty ?? false) contact.phone!.trim(),
      if (contact.email?.trim().isNotEmpty ?? false) contact.email!.trim(),
      if (contact.isPrimary) 'principal',
    ];
    return details.join(' - ');
  }
}

class _CompactItem extends StatelessWidget {
  const _CompactItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.primary),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: colors.primary),
              const SizedBox(width: AppSpacing.spacing8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          ...children,
        ],
      ),
    );
  }
}

class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _SubsectionTitle extends StatelessWidget {
  const _SubsectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
          ),
        ),
        Text(
          trailing,
          style: AppTypography.labelMedium.copyWith(color: colors.outline),
        ),
      ],
    );
  }
}

class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.info.withValues(alpha: 0.09),
          colors.surface,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.info.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: colors.info),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: colors.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: AppTypography.bodyMedium.copyWith(color: colors.outline),
      ),
    );
  }
}

String? _preferredPhone(Customer customer) {
  final fromCustomer = customer.primaryPhone?.trim();
  if (fromCustomer != null && fromCustomer.isNotEmpty) return fromCustomer;
  for (final contact in _sortedContacts(customer.contacts)) {
    final phone = contact.phone?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
  }
  return null;
}

String? _preferredEmail(Customer customer) {
  final fromCustomer = customer.primaryEmail?.trim();
  if (fromCustomer != null && fromCustomer.isNotEmpty) return fromCustomer;
  for (final contact in _sortedContacts(customer.contacts)) {
    final email = contact.email?.trim();
    if (email != null && email.isNotEmpty) return email;
  }
  return null;
}

List<CustomerContact> _sortedContacts(List<CustomerContact> contacts) {
  return <CustomerContact>[
    ...contacts.where((contact) => contact.isPrimary),
    ...contacts.where((contact) => !contact.isPrimary),
  ];
}

String _statusLabel(CustomerStatus status) {
  return switch (status) {
    CustomerStatus.active => 'Ativo',
    CustomerStatus.inactive => 'Inativo',
    CustomerStatus.prospect => 'Prospect',
    CustomerStatus.blocked => 'Bloqueado',
  };
}

AppStatusBadgeVariant _statusVariant(CustomerStatus status) {
  return switch (status) {
    CustomerStatus.active => AppStatusBadgeVariant.success,
    CustomerStatus.inactive => AppStatusBadgeVariant.neutral,
    CustomerStatus.prospect => AppStatusBadgeVariant.info,
    CustomerStatus.blocked => AppStatusBadgeVariant.error,
  };
}

AppStatusBadgeVariant _healthBandVariant(CustomerHealthScoreBand band) {
  return switch (band) {
    CustomerHealthScoreBand.healthy => AppStatusBadgeVariant.success,
    CustomerHealthScoreBand.attention => AppStatusBadgeVariant.warning,
    CustomerHealthScoreBand.risk => AppStatusBadgeVariant.error,
  };
}

String _syncLabel(CustomerSyncStatus status) {
  return switch (status) {
    CustomerSyncStatus.synced => 'Sincronizado',
    CustomerSyncStatus.pending => 'Pendente de sync',
    CustomerSyncStatus.syncing => 'Sincronizando',
    CustomerSyncStatus.failed => 'Sync falhou',
    CustomerSyncStatus.conflict => 'Conflito de sync',
  };
}

String _customerTypeLabel(CustomerType type) {
  return switch (type) {
    CustomerType.legalEntity => 'Pessoa juridica',
    CustomerType.individual => 'Pessoa fisica',
  };
}

String _lastPurchaseLabel(DateTime? date) {
  if (date == null) return 'Sem compra registrada';
  return 'Ultima compra ${_dateLabel(date)}';
}

String _dateLabel(DateTime date) {
  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');
  return '$day/$month/${localDate.year}';
}
