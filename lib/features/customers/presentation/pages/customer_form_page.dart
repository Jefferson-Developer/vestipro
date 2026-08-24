import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../users/users.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/entities/customer_contact.dart';
import '../../domain/value_objects/customer_address_type.dart';
import '../../domain/value_objects/customer_contact_type.dart';
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
    required this.classificationFocus,
    required this.potentialFocus,
  });

  final CustomerFormState state;
  final FocusNode documentFocus;
  final FocusNode legalNameFocus;
  final FocusNode fullNameFocus;
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
              _CustomerAddressesSection(state: state),
              const SizedBox(height: AppSpacing.spacing24),
              _CustomerContactsSection(state: state),
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

class _CustomerAddressesSection extends StatefulWidget {
  const _CustomerAddressesSection({required this.state});

  final CustomerFormState state;

  @override
  State<_CustomerAddressesSection> createState() =>
      _CustomerAddressesSectionState();
}

class _CustomerAddressesSectionState extends State<_CustomerAddressesSection> {
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  CustomerAddress? _editing;
  late var _selectedType = widget.state.config.addressTypes.first;
  bool _showForm = false;
  bool _isPrimary = false;
  bool _submitted = false;

  @override
  void didUpdateWidget(covariant _CustomerAddressesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasSelectedType = widget.state.config.addressTypes.any(
      (type) => type.code == _selectedType.code,
    );
    if (!hasSelectedType) {
      _selectedType = widget.state.config.addressTypes.first;
    }
    final changed = oldWidget.state.addresses != widget.state.addresses;
    if (_submitted && changed && !_hasErrors) {
      _resetForm();
    }
  }

  bool get _hasErrors {
    return widget.state.fieldErrors.keys.any(
      (field) => field.startsWith('address.'),
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(
          title: 'Endereços',
          actionLabel: 'Novo endereço',
          actionIcon: Icons.add_location_alt_outlined,
          isDisabled: widget.state.isSubmitting,
          onAction: () => _resetForm(keepClosed: false),
        ),
        if (_showForm) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing12),
          _AddressInlineForm(
            state: widget.state,
            selectedType: _selectedType,
            streetController: _streetController,
            numberController: _numberController,
            districtController: _districtController,
            cityController: _cityController,
            stateController: _stateController,
            zipCodeController: _zipCodeController,
            isPrimary: _isPrimary,
            isEditing: _editing != null,
            onTypeChanged: (type) => setState(() => _selectedType = type),
            onPrimaryChanged: (value) => setState(() => _isPrimary = value),
            onCancel: _resetForm,
            onSubmit: _submit,
          ),
          const SizedBox(height: AppSpacing.spacing12),
        ],
        if (widget.state.addresses.isEmpty)
          const AppEmptyState(
            title: 'Nenhum endereço cadastrado',
            description: 'Adicione entrega, cobrança ou outro endereço.',
            icon: Icons.location_off_outlined,
          )
        else
          Column(
            children: <Widget>[
              for (final address in widget.state.addresses) ...<Widget>[
                _AddressListItem(
                  address: address,
                  isDisabled: widget.state.isSubmitting,
                  onEdit: () => _edit(address),
                  onRemove: () => context.read<CustomerFormBloc>().add(
                    CustomerFormAddressRemoved(address.id),
                  ),
                  onSetPrimary: () => context.read<CustomerFormBloc>().add(
                    CustomerFormPrimaryAddressSelected(address.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
              ],
            ],
          ),
      ],
    );
  }

  void _submit() {
    _submitted = true;
    final bloc = context.read<CustomerFormBloc>();
    final editing = _editing;
    if (editing == null) {
      bloc.add(
        CustomerFormAddressAdded(
          type: _selectedType,
          street: _streetController.text,
          number: _numberController.text,
          district: _districtController.text,
          city: _cityController.text,
          state: _stateController.text,
          zipCode: _zipCodeController.text,
          isPrimary: _isPrimary,
        ),
      );
      return;
    }
    bloc.add(
      CustomerFormAddressUpdated(
        addressId: editing.id,
        type: _selectedType,
        street: _streetController.text,
        number: _numberController.text,
        district: _districtController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipCodeController.text,
        isPrimary: _isPrimary,
      ),
    );
  }

  void _edit(CustomerAddress address) {
    setState(() {
      _editing = address;
      _selectedType = address.type;
      _streetController.text = address.street;
      _numberController.text = address.number ?? '';
      _districtController.text = address.district ?? '';
      _cityController.text = address.city;
      _stateController.text = address.state;
      _zipCodeController.text = address.zipCode.formatted;
      _isPrimary = address.isPrimary;
      _showForm = true;
      _submitted = false;
    });
  }

  void _resetForm({bool keepClosed = true}) {
    setState(() {
      _editing = null;
      _selectedType = widget.state.config.addressTypes.first;
      _streetController.clear();
      _numberController.clear();
      _districtController.clear();
      _cityController.clear();
      _stateController.clear();
      _zipCodeController.clear();
      _isPrimary = widget.state.addresses.isEmpty;
      _showForm = !keepClosed;
      _submitted = false;
    });
  }
}

class _AddressInlineForm extends StatelessWidget {
  const _AddressInlineForm({
    required this.state,
    required this.selectedType,
    required this.streetController,
    required this.numberController,
    required this.districtController,
    required this.cityController,
    required this.stateController,
    required this.zipCodeController,
    required this.isPrimary,
    required this.isEditing,
    required this.onTypeChanged,
    required this.onPrimaryChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  final CustomerFormState state;
  final CustomerAddressType selectedType;
  final TextEditingController streetController;
  final TextEditingController numberController;
  final TextEditingController districtController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipCodeController;
  final bool isPrimary;
  final bool isEditing;
  final ValueChanged<CustomerAddressType> onTypeChanged;
  final ValueChanged<bool> onPrimaryChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppDropdown<CustomerAddressType>(
            label: 'Tipo de endereço',
            semanticLabel: 'Tipo de endereço',
            hintText: 'Selecione o tipo',
            closeSemanticLabel: 'Fechar tipo de endereço',
            enableSearch: false,
            options: state.config.addressTypes
                .map(
                  (type) => AppDropdownOption<CustomerAddressType>(
                    value: type,
                    label: type.label,
                  ),
                )
                .toList(growable: false),
            selectedValues: <CustomerAddressType>{selectedType},
            onChanged: state.isSubmitting
                ? (_) {}
                : (selected) => onTypeChanged(selected.first),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          _FieldGrid(
            children: <Widget>[
              AppTextField(
                controller: streetController,
                label: 'Logradouro',
                semanticLabel: 'Logradouro',
                isRequired: true,
                isDisabled: state.isSubmitting,
                errorText: state.fieldErrors['address.street'],
              ),
              AppTextField(
                controller: numberController,
                label: 'Número',
                semanticLabel: 'Número',
                isDisabled: state.isSubmitting,
              ),
              AppTextField(
                controller: districtController,
                label: 'Bairro',
                semanticLabel: 'Bairro',
                isDisabled: state.isSubmitting,
              ),
              AppTextField(
                controller: cityController,
                label: 'Cidade',
                semanticLabel: 'Cidade',
                isRequired: true,
                isDisabled: state.isSubmitting,
                errorText: state.fieldErrors['address.city'],
              ),
              AppTextField(
                controller: stateController,
                label: 'UF',
                semanticLabel: 'UF',
                isRequired: true,
                isDisabled: state.isSubmitting,
                maxLength: 2,
                errorText: state.fieldErrors['address.state'],
              ),
              AppTextField(
                controller: zipCodeController,
                label: 'CEP',
                semanticLabel: 'CEP',
                hintText: '00000-000',
                isRequired: true,
                isDisabled: state.isSubmitting,
                keyboardType: TextInputType.number,
                errorText: state.fieldErrors['address.zipCode'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: isPrimary,
              onChanged: state.isSubmitting
                  ? null
                  : (value) => onPrimaryChanged(value ?? false),
              title: const Text('Endereço principal'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          _InlineFormActions(
            submitLabel: isEditing
                ? 'Atualizar endereço'
                : 'Adicionar endereço',
            submitIcon: Icons.check,
            isDisabled: state.isSubmitting,
            onCancel: onCancel,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _AddressListItem extends StatelessWidget {
  const _AddressListItem({
    required this.address,
    required this.isDisabled,
    required this.onEdit,
    required this.onRemove,
    required this.onSetPrimary,
  });

  final CustomerAddress address;
  final bool isDisabled;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    return _ListItemShell(
      leadingIcon: Icons.location_on_outlined,
      title: '${address.type.label} • ${address.summary}',
      subtitle: '${address.zipCode.formatted} • ${address.district ?? '-'}',
      isPrimary: address.isPrimary,
      isDisabled: isDisabled,
      primarySemanticLabel: 'Definir endereço principal',
      editSemanticLabel: 'Editar endereço',
      removeSemanticLabel: 'Remover endereço',
      onSetPrimary: onSetPrimary,
      onEdit: onEdit,
      onRemove: onRemove,
    );
  }
}

class _CustomerContactsSection extends StatefulWidget {
  const _CustomerContactsSection({required this.state});

  final CustomerFormState state;

  @override
  State<_CustomerContactsSection> createState() =>
      _CustomerContactsSectionState();
}

class _CustomerContactsSectionState extends State<_CustomerContactsSection> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  CustomerContact? _editing;
  late var _selectedType = widget.state.config.contactTypes.first;
  bool _showForm = false;
  bool _isPrimary = false;
  bool _submitted = false;

  @override
  void didUpdateWidget(covariant _CustomerContactsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasSelectedType = widget.state.config.contactTypes.any(
      (type) => type.code == _selectedType.code,
    );
    if (!hasSelectedType) {
      _selectedType = widget.state.config.contactTypes.first;
    }
    final changed = oldWidget.state.contacts != widget.state.contacts;
    if (_submitted && changed && !_hasErrors) {
      _resetForm();
    }
  }

  bool get _hasErrors {
    return widget.state.fieldErrors.keys.any(
      (field) => field.startsWith('contact.'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SectionHeader(
          title: 'Contatos',
          actionLabel: 'Novo contato',
          actionIcon: Icons.person_add_alt_outlined,
          isDisabled: widget.state.isSubmitting,
          onAction: () => _resetForm(keepClosed: false),
        ),
        _SectionErrorText(message: widget.state.fieldErrors['primaryPhone']),
        _SectionErrorText(message: widget.state.fieldErrors['primaryEmail']),
        if (_showForm) ...<Widget>[
          const SizedBox(height: AppSpacing.spacing12),
          _ContactInlineForm(
            state: widget.state,
            selectedType: _selectedType,
            nameController: _nameController,
            roleController: _roleController,
            phoneController: _phoneController,
            emailController: _emailController,
            isPrimary: _isPrimary,
            isEditing: _editing != null,
            onTypeChanged: (type) => setState(() => _selectedType = type),
            onPrimaryChanged: (value) => setState(() => _isPrimary = value),
            onCancel: _resetForm,
            onSubmit: _submit,
          ),
          const SizedBox(height: AppSpacing.spacing12),
        ],
        if (widget.state.contacts.isEmpty)
          const AppEmptyState(
            title: 'Nenhum contato cadastrado',
            description: 'Adicione comprador, financeiro ou outro contato.',
            icon: Icons.person_off_outlined,
          )
        else
          Column(
            children: <Widget>[
              for (final contact in widget.state.contacts) ...<Widget>[
                _ContactListItem(
                  contact: contact,
                  isDisabled: widget.state.isSubmitting,
                  onEdit: () => _edit(contact),
                  onRemove: () => context.read<CustomerFormBloc>().add(
                    CustomerFormContactRemoved(contact.id),
                  ),
                  onSetPrimary: () => context.read<CustomerFormBloc>().add(
                    CustomerFormPrimaryContactSelected(contact.id),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
              ],
            ],
          ),
      ],
    );
  }

  void _submit() {
    _submitted = true;
    final bloc = context.read<CustomerFormBloc>();
    final editing = _editing;
    if (editing == null) {
      bloc.add(
        CustomerFormContactAdded(
          type: _selectedType,
          name: _nameController.text,
          role: _roleController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          isPrimary: _isPrimary,
        ),
      );
      return;
    }
    bloc.add(
      CustomerFormContactUpdated(
        contactId: editing.id,
        type: _selectedType,
        name: _nameController.text,
        role: _roleController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        isPrimary: _isPrimary,
      ),
    );
  }

  void _edit(CustomerContact contact) {
    setState(() {
      _editing = contact;
      _selectedType = contact.type;
      _nameController.text = contact.name;
      _roleController.text = contact.role ?? '';
      _phoneController.text = contact.phone ?? '';
      _emailController.text = contact.email ?? '';
      _isPrimary = contact.isPrimary;
      _showForm = true;
      _submitted = false;
    });
  }

  void _resetForm({bool keepClosed = true}) {
    setState(() {
      _editing = null;
      _selectedType = widget.state.config.contactTypes.first;
      _nameController.clear();
      _roleController.clear();
      _phoneController.clear();
      _emailController.clear();
      _isPrimary = widget.state.contacts.isEmpty;
      _showForm = !keepClosed;
      _submitted = false;
    });
  }
}

class _ContactInlineForm extends StatelessWidget {
  const _ContactInlineForm({
    required this.state,
    required this.selectedType,
    required this.nameController,
    required this.roleController,
    required this.phoneController,
    required this.emailController,
    required this.isPrimary,
    required this.isEditing,
    required this.onTypeChanged,
    required this.onPrimaryChanged,
    required this.onCancel,
    required this.onSubmit,
  });

  final CustomerFormState state;
  final CustomerContactType selectedType;
  final TextEditingController nameController;
  final TextEditingController roleController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool isPrimary;
  final bool isEditing;
  final ValueChanged<CustomerContactType> onTypeChanged;
  final ValueChanged<bool> onPrimaryChanged;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppDropdown<CustomerContactType>(
            label: 'Tipo de contato',
            semanticLabel: 'Tipo de contato',
            hintText: 'Selecione o tipo',
            closeSemanticLabel: 'Fechar tipo de contato',
            enableSearch: false,
            options: state.config.contactTypes
                .map(
                  (type) => AppDropdownOption<CustomerContactType>(
                    value: type,
                    label: type.label,
                  ),
                )
                .toList(growable: false),
            selectedValues: <CustomerContactType>{selectedType},
            onChanged: state.isSubmitting
                ? (_) {}
                : (selected) => onTypeChanged(selected.first),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          _FieldGrid(
            children: <Widget>[
              AppTextField(
                controller: nameController,
                label: 'Nome do contato',
                semanticLabel: 'Nome do contato',
                isRequired: true,
                isDisabled: state.isSubmitting,
                errorText: state.fieldErrors['contact.name'],
              ),
              AppTextField(
                controller: roleController,
                label: 'Cargo',
                semanticLabel: 'Cargo',
                isDisabled: state.isSubmitting,
              ),
              AppTextField(
                controller: phoneController,
                label: 'Telefone do contato',
                semanticLabel: 'Telefone do contato',
                hintText: '(00) 00000-0000',
                isDisabled: state.isSubmitting,
                keyboardType: TextInputType.phone,
                errorText: state.fieldErrors['contact.phone'],
              ),
              AppTextField(
                controller: emailController,
                label: 'E-mail do contato',
                semanticLabel: 'E-mail do contato',
                hintText: 'contato@cliente.com.br',
                isDisabled: state.isSubmitting,
                keyboardType: TextInputType.emailAddress,
                errorText: state.fieldErrors['contact.email'],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Material(
            color: Colors.transparent,
            child: CheckboxListTile(
              value: isPrimary,
              onChanged: state.isSubmitting
                  ? null
                  : (value) => onPrimaryChanged(value ?? false),
              title: const Text('Contato principal'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          _InlineFormActions(
            submitLabel: isEditing ? 'Atualizar contato' : 'Adicionar contato',
            submitIcon: Icons.check,
            isDisabled: state.isSubmitting,
            onCancel: onCancel,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _ContactListItem extends StatelessWidget {
  const _ContactListItem({
    required this.contact,
    required this.isDisabled,
    required this.onEdit,
    required this.onRemove,
    required this.onSetPrimary,
  });

  final CustomerContact contact;
  final bool isDisabled;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback onSetPrimary;

  @override
  Widget build(BuildContext context) {
    final channel = <String>[
      if (contact.phone != null) contact.phone!,
      if (contact.email != null) contact.email!,
    ].join(' • ');
    return _ListItemShell(
      leadingIcon: Icons.person_outline,
      title: '${contact.name} • ${contact.type.label}',
      subtitle: [
        if (contact.role != null) contact.role!,
        channel,
      ].where((value) => value.isNotEmpty).join(' • '),
      isPrimary: contact.isPrimary,
      isDisabled: isDisabled,
      primarySemanticLabel: 'Definir contato principal',
      editSemanticLabel: 'Editar contato',
      removeSemanticLabel: 'Remover contato',
      onSetPrimary: onSetPrimary,
      onEdit: onEdit,
      onRemove: onRemove,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.isDisabled,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final bool isDisabled;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = _SectionTitle(this.title);
        final action = AppButton(
          label: actionLabel,
          leadingIcon: actionIcon,
          variant: AppButtonVariant.secondary,
          isDisabled: isDisabled,
          onPressed: isDisabled ? null : onAction,
        );
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[title, action],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(child: title),
            action,
          ],
        );
      },
    );
  }
}

class _InlineFormActions extends StatelessWidget {
  const _InlineFormActions({
    required this.submitLabel,
    required this.submitIcon,
    required this.isDisabled,
    required this.onCancel,
    required this.onSubmit,
  });

  final String submitLabel;
  final IconData submitIcon;
  final bool isDisabled;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cancel = AppButton(
          label: 'Cancelar',
          variant: AppButtonVariant.text,
          isDisabled: isDisabled,
          onPressed: isDisabled ? null : onCancel,
        );
        final submit = AppButton(
          label: submitLabel,
          leadingIcon: submitIcon,
          isDisabled: isDisabled,
          onPressed: isDisabled ? null : onSubmit,
        );
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              cancel,
              const SizedBox(height: AppSpacing.spacing8),
              submit,
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            cancel,
            const SizedBox(width: AppSpacing.spacing8),
            submit,
          ],
        );
      },
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: <Widget>[
              for (final child in children) ...<Widget>[
                child,
                const SizedBox(height: AppSpacing.spacing12),
              ],
            ],
          );
        }
        return Wrap(
          runSpacing: AppSpacing.spacing12,
          spacing: AppSpacing.spacing12,
          children: <Widget>[
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.spacing12) / 2,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _ListItemShell extends StatelessWidget {
  const _ListItemShell({
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.isDisabled,
    required this.primarySemanticLabel,
    required this.editSemanticLabel,
    required this.removeSemanticLabel,
    required this.onSetPrimary,
    required this.onEdit,
    required this.onRemove,
  });

  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final bool isDisabled;
  final String primarySemanticLabel;
  final String editSemanticLabel;
  final String removeSemanticLabel;
  final VoidCallback onSetPrimary;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(leadingIcon, color: colors.primary, size: AppIconSizes.lg),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: AppSpacing.spacing8,
                  runSpacing: AppSpacing.spacing4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                    if (isPrimary)
                      const AppStatusBadge(
                        label: 'Principal',
                        variant: AppStatusBadgeVariant.info,
                        icon: Icons.star,
                      ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    subtitle,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Wrap(
            children: <Widget>[
              AppIconButton(
                icon: Icons.star_border,
                semanticLabel: primarySemanticLabel,
                isDisabled: isDisabled || isPrimary,
                onPressed: isDisabled || isPrimary ? null : onSetPrimary,
              ),
              AppIconButton(
                icon: Icons.edit_outlined,
                semanticLabel: editSemanticLabel,
                isDisabled: isDisabled,
                onPressed: isDisabled ? null : onEdit,
              ),
              AppIconButton(
                icon: Icons.delete_outline,
                semanticLabel: removeSemanticLabel,
                variant: AppButtonVariant.destructive,
                isDisabled: isDisabled,
                onPressed: isDisabled ? null : onRemove,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionErrorText extends StatelessWidget {
  const _SectionErrorText({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      child: Text(
        message!,
        style: AppTypography.bodySmall.copyWith(color: context.colors.error),
      ),
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
