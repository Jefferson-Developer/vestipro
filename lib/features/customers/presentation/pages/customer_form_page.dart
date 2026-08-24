import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../users/users.dart';
import '../../domain/entities/customer.dart';
import '../../domain/value_objects/customer_required_field.dart';
import '../../domain/value_objects/customer_type.dart';
import '../bloc/customer_form_bloc.dart';
import '../bloc/customer_form_event.dart';
import '../bloc/customer_form_state.dart';

class CustomerFormPage extends StatelessWidget {
  const CustomerFormPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialCustomer,
    this.onSaved,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final CustomerFormBloc Function() createBloc;
  final Customer? initialCustomer;
  final void Function(Customer customer)? onSaved;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: initialCustomer == null
          ? Capability.customerCreate
          : Capability.customerUpdate,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return _ResponsibleSellerPermissionGate(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
          permissionService: permissionService,
          createBloc: createBloc,
          initialCustomer: initialCustomer,
          onSaved: onSaved,
        );
      },
    );
  }
}

class _ResponsibleSellerPermissionGate extends StatefulWidget {
  const _ResponsibleSellerPermissionGate({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialCustomer,
    this.onSaved,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final CustomerFormBloc Function() createBloc;
  final Customer? initialCustomer;
  final void Function(Customer customer)? onSaved;

  @override
  State<_ResponsibleSellerPermissionGate> createState() =>
      _ResponsibleSellerPermissionGateState();
}

class _ResponsibleSellerPermissionGateState
    extends State<_ResponsibleSellerPermissionGate> {
  late final Future<bool> _canChooseResponsibleSeller;

  @override
  void initState() {
    super.initState();
    _canChooseResponsibleSeller = widget.permissionService
        .hasPermission(
          organizationId: widget.organizationId,
          userId: widget.userId,
          capability: Capability.teamManage,
        )
        .then(
          (result) => result.fold(
            onSuccess: (granted) => granted,
            onFailure: (_) => false,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canChooseResponsibleSeller,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider<CustomerFormBloc>(
          create: (_) => widget.createBloc()
            ..add(
              CustomerFormStarted(
                organizationId: widget.organizationId,
                companyId: widget.companyId,
                userId: widget.userId,
                canChooseResponsibleSeller: snapshot.data!,
                initialCustomer: widget.initialCustomer,
              ),
            ),
          child: Scaffold(
            body: AppAdminPageLayout(
              title: widget.initialCustomer == null
                  ? 'Novo cliente'
                  : 'Editar cliente',
              content: _CustomerFormView(onSaved: widget.onSaved),
            ),
          ),
        );
      },
    );
  }
}

class _CustomerFormView extends StatefulWidget {
  const _CustomerFormView({this.onSaved});

  final void Function(Customer customer)? onSaved;

  @override
  State<_CustomerFormView> createState() => _CustomerFormViewState();
}

class _CustomerFormViewState extends State<_CustomerFormView> {
  final _documentFocus = FocusNode(debugLabel: 'customer.document');
  final _legalNameFocus = FocusNode(debugLabel: 'customer.legalName');
  final _fullNameFocus = FocusNode(debugLabel: 'customer.fullName');
  final _emailFocus = FocusNode(debugLabel: 'customer.primaryEmail');
  final _phoneFocus = FocusNode(debugLabel: 'customer.primaryPhone');
  final _classificationFocus = FocusNode(debugLabel: 'customer.classification');
  final _potentialFocus = FocusNode(debugLabel: 'customer.potential');

  @override
  void dispose() {
    _documentFocus.dispose();
    _legalNameFocus.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _classificationFocus.dispose();
    _potentialFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerFormBloc, CustomerFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus ||
          previous.draftStatus != current.draftStatus ||
          previous.hasRestoredDraft != current.hasRestoredDraft,
      listener: (context, state) {
        if (state.hasRestoredDraft) {
          AppSnackbar.show(
            context,
            message: 'Rascunho recuperado.',
            variant: AppSnackbarVariant.info,
          );
        }
        if (state.draftStatus == CustomerFormDraftStatus.saved) {
          AppSnackbar.show(
            context,
            message: 'Rascunho salvo.',
            variant: AppSnackbarVariant.success,
          );
        }
        if (state.draftStatus == CustomerFormDraftStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Não foi possível salvar.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == CustomerFormSubmissionStatus.failure) {
          _focusFirstError(state);
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos do cliente.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == CustomerFormSubmissionStatus.success &&
            state.savedCustomer != null) {
          widget.onSaved?.call(state.savedCustomer!);
          AppSnackbar.show(
            context,
            message: state.wasSavedOffline
                ? 'Cliente salvo localmente e pendente de sincronização.'
                : 'Cliente salvo.',
            variant: state.wasSavedOffline
                ? AppSnackbarVariant.warning
                : AppSnackbarVariant.success,
          );
        }
      },
      builder: (context, state) {
        return switch (state.loadStatus) {
          CustomerFormLoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          CustomerFormLoadStatus.failure => AppErrorState(
            title: 'Não foi possível carregar o cadastro',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          CustomerFormLoadStatus.ready => _CustomerFormContent(
            state: state,
            documentFocus: _documentFocus,
            legalNameFocus: _legalNameFocus,
            fullNameFocus: _fullNameFocus,
            emailFocus: _emailFocus,
            phoneFocus: _phoneFocus,
            classificationFocus: _classificationFocus,
            potentialFocus: _potentialFocus,
          ),
        };
      },
    );
  }

  void _focusFirstError(CustomerFormState state) {
    final order = <String>[
      'document',
      if (state.type == CustomerType.legalEntity) 'legalName' else 'fullName',
      'primaryPhone',
      'primaryEmail',
      'classification',
      'potential',
    ];
    final focusByField = <String, FocusNode>{
      'document': _documentFocus,
      'legalName': _legalNameFocus,
      'fullName': _fullNameFocus,
      'primaryEmail': _emailFocus,
      'primaryPhone': _phoneFocus,
      'classification': _classificationFocus,
      'potential': _potentialFocus,
    };

    for (final field in order) {
      if (state.fieldErrors.containsKey(field)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) focusByField[field]?.requestFocus();
        });
        return;
      }
    }
  }
}

class _CustomerFormContent extends StatelessWidget {
  const _CustomerFormContent({
    required this.state,
    required this.documentFocus,
    required this.legalNameFocus,
    required this.fullNameFocus,
    required this.emailFocus,
    required this.phoneFocus,
    required this.classificationFocus,
    required this.potentialFocus,
  });

  final CustomerFormState state;
  final FocusNode documentFocus;
  final FocusNode legalNameFocus;
  final FocusNode fullNameFocus;
  final FocusNode emailFocus;
  final FocusNode phoneFocus;
  final FocusNode classificationFocus;
  final FocusNode potentialFocus;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SectionTitle('Identificação'),
              _CustomerTypeSelector(state: state),
              const SizedBox(height: AppSpacing.spacing16),
              _SyncedAppTextField(
                value: state.document,
                label: state.type == CustomerType.legalEntity ? 'CNPJ' : 'CPF',
                hintText: state.type == CustomerType.legalEntity
                    ? '00.000.000/0000-00'
                    : '000.000.000-00',
                semanticLabel: state.type == CustomerType.legalEntity
                    ? 'CNPJ'
                    : 'CPF',
                isRequired: true,
                isDisabled: state.isSubmitting,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['document'],
                focusNode: documentFocus,
                onChanged: (value) => context.read<CustomerFormBloc>().add(
                  CustomerFormDocumentChanged(value),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              if (state.type == CustomerType.legalEntity)
                _LegalEntityFields(state: state, legalNameFocus: legalNameFocus)
              else
                _IndividualFields(state: state, fullNameFocus: fullNameFocus),
              const SizedBox(height: AppSpacing.spacing24),
              const _SectionTitle('Contato principal'),
              _SyncedAppTextField(
                value: state.primaryPhone,
                label: 'Telefone principal',
                hintText: '(00) 00000-0000',
                semanticLabel: 'Telefone principal',
                isRequired: state.isRequired(
                  CustomerRequiredField.primaryPhone,
                ),
                isDisabled: state.isSubmitting,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['primaryPhone'],
                focusNode: phoneFocus,
                onChanged: (value) => context.read<CustomerFormBloc>().add(
                  CustomerFormPrimaryPhoneChanged(value),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              _SyncedAppTextField(
                value: state.primaryEmail,
                label: 'E-mail principal',
                hintText: 'contato@cliente.com.br',
                semanticLabel: 'E-mail principal',
                isRequired: state.isRequired(
                  CustomerRequiredField.primaryEmail,
                ),
                isDisabled: state.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['primaryEmail'],
                focusNode: emailFocus,
                onChanged: (value) => context.read<CustomerFormBloc>().add(
                  CustomerFormPrimaryEmailChanged(value),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing24),
              const _SectionTitle('Classificação e potencial'),
              _SyncedAppTextField(
                value: state.classification,
                label: 'Classificação',
                hintText: 'Ex.: Atacado premium',
                semanticLabel: 'Classificação',
                isRequired: state.isRequired(
                  CustomerRequiredField.classification,
                ),
                isDisabled: state.isSubmitting,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['classification'],
                focusNode: classificationFocus,
                onChanged: (value) => context.read<CustomerFormBloc>().add(
                  CustomerFormClassificationChanged(value),
                ),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              _SyncedAppTextField(
                value: state.potential,
                label: 'Potencial',
                hintText: 'Ex.: Alto',
                semanticLabel: 'Potencial',
                isRequired: state.isRequired(CustomerRequiredField.potential),
                isDisabled: state.isSubmitting,
                textInputAction: state.canChooseResponsibleSeller
                    ? TextInputAction.next
                    : TextInputAction.done,
                errorText: state.fieldErrors['potential'],
                focusNode: potentialFocus,
                onChanged: (value) => context.read<CustomerFormBloc>().add(
                  CustomerFormPotentialChanged(value),
                ),
              ),
              if (state.canChooseResponsibleSeller) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing24),
                const _SectionTitle('Vendedor responsável'),
                _ResponsibleSellerField(state: state),
              ],
              const SizedBox(height: AppSpacing.spacing32),
              _CustomerFormActions(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerTypeSelector extends StatelessWidget {
  const _CustomerTypeSelector({required this.state});

  final CustomerFormState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SegmentedButton<CustomerType>(
      segments: const <ButtonSegment<CustomerType>>[
        ButtonSegment<CustomerType>(
          value: CustomerType.legalEntity,
          icon: Icon(Icons.storefront_outlined),
          label: Text('Pessoa jurídica'),
        ),
        ButtonSegment<CustomerType>(
          value: CustomerType.individual,
          icon: Icon(Icons.person_outline),
          label: Text('Pessoa física'),
        ),
      ],
      selected: <CustomerType>{state.type},
      onSelectionChanged: state.isSubmitting
          ? null
          : (selected) => context.read<CustomerFormBloc>().add(
              CustomerFormTypeChanged(selected.first),
            ),
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith<Color>(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.onSurface,
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.surface,
        ),
        textStyle: WidgetStateProperty.all(AppTypography.labelLarge),
      ),
    );
  }
}

class _LegalEntityFields extends StatelessWidget {
  const _LegalEntityFields({required this.state, required this.legalNameFocus});

  final CustomerFormState state;
  final FocusNode legalNameFocus;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CustomerFormBloc>();

    return Column(
      children: <Widget>[
        _SyncedAppTextField(
          value: state.legalName,
          label: 'Razão social',
          hintText: 'Nome jurídico do cliente',
          semanticLabel: 'Razão social',
          isRequired: true,
          isDisabled: state.isSubmitting,
          textInputAction: TextInputAction.next,
          errorText: state.fieldErrors['legalName'],
          focusNode: legalNameFocus,
          onChanged: (value) => bloc.add(CustomerFormLegalNameChanged(value)),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        _SyncedAppTextField(
          value: state.tradeName,
          label: 'Nome fantasia',
          hintText: 'Nome comercial',
          semanticLabel: 'Nome fantasia',
          isDisabled: state.isSubmitting,
          textInputAction: TextInputAction.next,
          onChanged: (value) => bloc.add(CustomerFormTradeNameChanged(value)),
        ),
        const SizedBox(height: AppSpacing.spacing16),
        _SyncedAppTextField(
          value: state.stateRegistration,
          label: 'Inscrição estadual',
          hintText: 'Isento ou número da IE',
          semanticLabel: 'Inscrição estadual',
          isDisabled: state.isSubmitting,
          textInputAction: TextInputAction.next,
          errorText: state.fieldErrors['stateRegistration'],
          onChanged: (value) =>
              bloc.add(CustomerFormStateRegistrationChanged(value)),
        ),
      ],
    );
  }
}

class _IndividualFields extends StatelessWidget {
  const _IndividualFields({required this.state, required this.fullNameFocus});

  final CustomerFormState state;
  final FocusNode fullNameFocus;

  @override
  Widget build(BuildContext context) {
    return _SyncedAppTextField(
      value: state.fullName,
      label: 'Nome completo',
      hintText: 'Nome do cliente',
      semanticLabel: 'Nome completo',
      isRequired: true,
      isDisabled: state.isSubmitting,
      textInputAction: TextInputAction.next,
      errorText: state.fieldErrors['fullName'],
      focusNode: fullNameFocus,
      onChanged: (value) => context.read<CustomerFormBloc>().add(
        CustomerFormFullNameChanged(value),
      ),
    );
  }
}

class _ResponsibleSellerField extends StatelessWidget {
  const _ResponsibleSellerField({required this.state});

  final CustomerFormState state;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<String>(
      label: 'Vendedor responsável',
      hintText: 'Selecione um vendedor',
      semanticLabel: 'Vendedor responsável',
      isRequired: state.isRequired(CustomerRequiredField.responsibleSellerId),
      isDisabled: state.isSubmitting,
      closeSemanticLabel: 'Fechar seleção de vendedor',
      searchHintText: 'Buscar vendedor',
      noResultsLabel: 'Nenhum vendedor disponível',
      errorText: state.fieldErrors['responsibleSellerId'],
      options: state.responsibleSellers
          .map(_sellerOption)
          .toList(growable: false),
      selectedValues:
          state.responsibleSellerId == null ||
              state.responsibleSellerId!.isEmpty
          ? const <String>{}
          : <String>{state.responsibleSellerId!},
      onChanged: state.isSubmitting
          ? (_) {}
          : (selected) => context.read<CustomerFormBloc>().add(
              CustomerFormResponsibleSellerSelected(
                selected.isEmpty ? null : selected.first,
              ),
            ),
    );
  }

  AppDropdownOption<String> _sellerOption(OrganizationUser user) {
    final email = user.email.isEmpty ? '' : ' • ${user.email}';
    return AppDropdownOption<String>(
      value: user.userId,
      label: '${user.name}$email',
    );
  }
}

class _CustomerFormActions extends StatelessWidget {
  const _CustomerFormActions({required this.state});

  final CustomerFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CustomerFormBloc>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final draftButton = AppButton(
          label: 'Salvar rascunho',
          leadingIcon: Icons.bookmark_border,
          variant: AppButtonVariant.secondary,
          isLoading: state.isDraftSaving,
          isDisabled: state.isSubmitting,
          expand: constraints.maxWidth < 560,
          onPressed: state.isSubmitting || state.isDraftSaving
              ? null
              : () => bloc.add(const CustomerFormDraftSaved()),
        );
        final submitButton = AppButton(
          label: state.isEditing ? 'Salvar alterações' : 'Salvar cliente',
          leadingIcon: Icons.save_outlined,
          isLoading: state.isSubmitting,
          expand: constraints.maxWidth < 560,
          onPressed: state.isSubmitting
              ? null
              : () => bloc.add(const CustomerFormSubmitted()),
        );

        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              draftButton,
              const SizedBox(height: AppSpacing.spacing12),
              submitButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            draftButton,
            const SizedBox(width: AppSpacing.spacing12),
            submitButton,
          ],
        );
      },
    );
  }
}

class _SyncedAppTextField extends StatefulWidget {
  const _SyncedAppTextField({
    required this.value,
    required this.label,
    required this.onChanged,
    this.hintText,
    this.semanticLabel,
    this.errorText,
    this.isRequired = false,
    this.isDisabled = false,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
  });

  final String value;
  final String label;
  final String? hintText;
  final String? semanticLabel;
  final String? errorText;
  final bool isRequired;
  final bool isDisabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String> onChanged;

  @override
  State<_SyncedAppTextField> createState() => _SyncedAppTextFieldState();
}

class _SyncedAppTextFieldState extends State<_SyncedAppTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _SyncedAppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: _controller,
      label: widget.label,
      hintText: widget.hintText,
      semanticLabel: widget.semanticLabel,
      errorText: widget.errorText,
      isRequired: widget.isRequired,
      isDisabled: widget.isDisabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
      child: Text(
        label,
        style: AppTypography.titleMedium.copyWith(
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}
