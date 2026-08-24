import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../crm/crm.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
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
    super.key,
  });

  final String organizationId;
  final String customerId;
  final String userId;
  final PermissionService permissionService;
  final CustomerDetailBloc Function() createBloc;

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
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;

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
  });

  final CustomerDetailState state;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;

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
      organizationId: organizationId,
      userId: userId,
      permissionService: permissionService,
    );
  }
}

class _CustomerDetailContent extends StatelessWidget {
  const _CustomerDetailContent({
    required this.customer,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final Customer customer;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;

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
                organizationId: organizationId,
                userId: userId,
                permissionService: permissionService,
              )
            : _StackedCustomerDetail(
                customer: customer,
                organizationId: organizationId,
                userId: userId,
                permissionService: permissionService,
              );

        return SingleChildScrollView(key: key, child: content);
      },
    );
  }
}

class _StackedCustomerDetail extends StatelessWidget {
  const _StackedCustomerDetail({
    required this.customer,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final Customer customer;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CustomerHeader(
          customer: customer,
          onRegisterActivity: () => _showRegisterActivitySheet(context),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        _RegistrationSection(customer: customer),
        const SizedBox(height: AppSpacing.spacing16),
        _IndicatorSection(customer: customer),
        const SizedBox(height: AppSpacing.spacing16),
        _SensitiveCommercialSection(
          organizationId: organizationId,
          userId: userId,
          permissionService: permissionService,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        const _TimelineSection(),
        const SizedBox(height: AppSpacing.spacing16),
        const _OpportunitiesSection(),
        const SizedBox(height: AppSpacing.spacing16),
        const _OrderHistorySection(),
        const SizedBox(height: AppSpacing.spacing16),
        const _NextBestActionSection(),
      ],
    );
  }
}

class _DesktopCustomerDetail extends StatelessWidget {
  const _DesktopCustomerDetail({
    required this.customer,
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final Customer customer;
  final String organizationId;
  final String userId;
  final PermissionService permissionService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _CustomerHeader(
          customer: customer,
          onRegisterActivity: () => _showRegisterActivitySheet(context),
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
                    userId: userId,
                    permissionService: permissionService,
                  ),
                  const SizedBox(height: AppSpacing.spacing16),
                  const _OpportunitiesSection(),
                  const SizedBox(height: AppSpacing.spacing16),
                  const _NextBestActionSection(),
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
  });

  final Customer customer;
  final VoidCallback onRegisterActivity;

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
  });

  final Customer customer;
  final VoidCallback onRegisterActivity;

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
      ],
    );
  }

  static void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<void> _showRegisterActivitySheet(BuildContext context) {
  final bloc = context.read<CustomerDetailBloc>();
  return AppBottomSheet.show<void>(
    context: context,
    title: 'Registrar atividade',
    contentKey: const Key('register-crm-activity-sheet'),
    builder: (sheetContext) => BlocProvider<CustomerDetailBloc>.value(
      value: bloc,
      child: const _RegisterActivitySheet(),
    ),
  );
}

class _RegisterActivitySheet extends StatefulWidget {
  const _RegisterActivitySheet();

  @override
  State<_RegisterActivitySheet> createState() => _RegisterActivitySheetState();
}

class _RegisterActivitySheetState extends State<_RegisterActivitySheet> {
  final _descriptionController = TextEditingController();
  CrmActivityType _type = CrmActivityType.phoneCall;
  String? _descriptionError;

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
          ],
        ),
        const SizedBox(height: AppSpacing.spacing12),
        const _ComingSoonPanel(
          title: 'Score do cliente em breve',
          description:
              'Nao disponivel ate a TASK-062 implementar score e health score.',
          icon: Icons.speed_outlined,
        ),
      ],
    );
  }
}

class _SensitiveCommercialSection extends StatelessWidget {
  const _SensitiveCommercialSection({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;

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
        return const _SectionCard(
          title: 'Indicadores comerciais sensiveis',
          icon: Icons.insights_outlined,
          children: <Widget>[
            _ComingSoonPanel(
              title: 'Margem e credito em breve',
              description:
                  'Nao disponivel ate pedidos, politicas comerciais e financeiro existirem.',
              icon: Icons.account_balance_wallet_outlined,
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
  const _NextBestActionSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      title: 'Proxima melhor acao',
      icon: Icons.auto_awesome_outlined,
      children: <Widget>[
        _ComingSoonPanel(
          title: 'Recomendacao em breve',
          description:
              'Nao disponivel ate a TASK-063 implementar recomendacoes rastreaveis.',
          icon: Icons.lightbulb_outline,
        ),
      ],
    );
  }
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
