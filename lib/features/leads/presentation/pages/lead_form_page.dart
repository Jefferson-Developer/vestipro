import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../users/users.dart';
import '../../domain/entities/lead.dart';
import '../../domain/value_objects/lead_source.dart';
import '../bloc/lead_form_bloc.dart';
import '../bloc/lead_form_event.dart';
import '../bloc/lead_form_state.dart';

/// Lead cadastro page (TASK-056), gated by [Capability.leadCreate]. Whether
/// the rep may reassign the lead to someone else is a second, independent
/// check ([Capability.teamManage], same capability `CustomerFormPage` uses
/// for the responsible-seller field) resolved before the form mounts, so the
/// dropdown only ever appears for callers actually authorized to choose it.
class LeadFormPage extends StatelessWidget {
  const LeadFormPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.companyId,
    this.onSaved,
    super.key,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final PermissionService permissionService;
  final LeadFormBloc Function() createBloc;
  final void Function(Lead lead)? onSaved;

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.leadCreate,
      builder: (context, granted) {
        if (!granted) return const ForbiddenPage();
        return _ResponsiblePermissionGate(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
          permissionService: permissionService,
          createBloc: createBloc,
          onSaved: onSaved,
        );
      },
    );
  }
}

class _ResponsiblePermissionGate extends StatefulWidget {
  const _ResponsiblePermissionGate({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.onSaved,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
  final PermissionService permissionService;
  final LeadFormBloc Function() createBloc;
  final void Function(Lead lead)? onSaved;

  @override
  State<_ResponsiblePermissionGate> createState() =>
      _ResponsiblePermissionGateState();
}

class _ResponsiblePermissionGateState
    extends State<_ResponsiblePermissionGate> {
  late final Future<bool> _canChooseResponsible;

  @override
  void initState() {
    super.initState();
    _canChooseResponsible = widget.permissionService
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
      future: _canChooseResponsible,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider<LeadFormBloc>(
          create: (_) => widget.createBloc()
            ..add(
              LeadFormStarted(
                organizationId: widget.organizationId,
                companyId: widget.companyId,
                userId: widget.userId,
                canChooseResponsible: snapshot.data!,
              ),
            ),
          child: Scaffold(
            body: AppAdminPageLayout(
              title: 'Novo lead',
              content: _LeadFormView(onSaved: widget.onSaved),
            ),
          ),
        );
      },
    );
  }
}

class _LeadFormView extends StatefulWidget {
  const _LeadFormView({this.onSaved});

  final void Function(Lead lead)? onSaved;

  @override
  State<_LeadFormView> createState() => _LeadFormViewState();
}

class _LeadFormViewState extends State<_LeadFormView> {
  final _nameFocus = FocusNode(debugLabel: 'lead.name');

  @override
  void dispose() {
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadFormBloc, LeadFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == LeadFormSubmissionStatus.failure) {
          _focusFirstError(state);
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos do lead.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == LeadFormSubmissionStatus.success &&
            state.savedLead != null) {
          widget.onSaved?.call(state.savedLead!);
          AppSnackbar.show(
            context,
            message: 'Lead cadastrado.',
            variant: AppSnackbarVariant.success,
          );
        }
      },
      builder: (context, state) {
        return switch (state.loadStatus) {
          LeadFormLoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          LeadFormLoadStatus.failure => AppErrorState(
            title: 'Nao foi possivel carregar o cadastro',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          LeadFormLoadStatus.ready => _LeadFormContent(
            state: state,
            nameFocus: _nameFocus,
          ),
        };
      },
    );
  }

  void _focusFirstError(LeadFormState state) {
    if (state.fieldErrors.containsKey('name')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocus.requestFocus();
      });
    }
  }
}

class _LeadFormContent extends StatelessWidget {
  const _LeadFormContent({required this.state, required this.nameFocus});

  final LeadFormState state;
  final FocusNode nameFocus;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LeadFormBloc>();
    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _SyncedAppTextField(
                value: state.name,
                label: 'Nome ou empresa',
                hintText: 'Ex.: Boutique Aurora',
                semanticLabel: 'Nome ou empresa do lead',
                isRequired: true,
                isDisabled: state.isSubmitting,
                textInputAction: TextInputAction.next,
                errorText: state.fieldErrors['name'],
                focusNode: nameFocus,
                onChanged: (value) => bloc.add(LeadFormNameChanged(value)),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              _SyncedAppTextField(
                value: state.document,
                label: 'CNPJ/CPF (opcional)',
                hintText: 'Se ja conhecido',
                semanticLabel: 'Documento do lead',
                isDisabled: state.isSubmitting,
                textInputAction: TextInputAction.next,
                onChanged: (value) => bloc.add(LeadFormDocumentChanged(value)),
              ),
              const SizedBox(height: AppSpacing.spacing16),
              AppDropdown<LeadSource>(
                label: 'Origem',
                semanticLabel: 'Origem do lead',
                hintText: 'Selecione a origem',
                closeSemanticLabel: 'Fechar selecao de origem',
                enableSearch: false,
                isDisabled: state.isSubmitting,
                errorText: state.fieldErrors['source'],
                options: LeadSource.defaults
                    .map(
                      (source) => AppDropdownOption<LeadSource>(
                        value: source,
                        label: source.label,
                      ),
                    )
                    .toList(growable: false),
                selectedValues: <LeadSource>{state.source},
                onChanged: state.isSubmitting
                    ? (_) {}
                    : (selected) =>
                          bloc.add(LeadFormSourceSelected(selected.first)),
              ),
              if (state.isCustomSource) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing16),
                _SyncedAppTextField(
                  value: state.customSourceLabel,
                  label: 'Descreva a origem (opcional)',
                  hintText: 'Ex.: Feira ABest, parceiro X',
                  semanticLabel: 'Descricao da origem do lead',
                  isDisabled: state.isSubmitting,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) =>
                      bloc.add(LeadFormCustomSourceLabelChanged(value)),
                ),
              ],
              if (state.canChooseResponsible) ...<Widget>[
                const SizedBox(height: AppSpacing.spacing16),
                _ResponsibleField(state: state),
              ],
              const SizedBox(height: AppSpacing.spacing32),
              _LeadFormActions(state: state),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsibleField extends StatelessWidget {
  const _ResponsibleField({required this.state});

  final LeadFormState state;

  @override
  Widget build(BuildContext context) {
    return AppDropdown<String>(
      label: 'Responsavel',
      hintText: 'Selecione um responsavel',
      semanticLabel: 'Responsavel pelo lead',
      isRequired: true,
      isDisabled: state.isSubmitting,
      closeSemanticLabel: 'Fechar selecao de responsavel',
      searchHintText: 'Buscar responsavel',
      noResultsLabel: 'Nenhum responsavel disponivel',
      errorText: state.fieldErrors['responsibleUserId'],
      options: state.responsibleUsers.map(_userOption).toList(growable: false),
      selectedValues:
          state.responsibleUserId == null || state.responsibleUserId!.isEmpty
          ? const <String>{}
          : <String>{state.responsibleUserId!},
      onChanged: state.isSubmitting
          ? (_) {}
          : (selected) => context.read<LeadFormBloc>().add(
              LeadFormResponsibleSelected(
                selected.isEmpty ? null : selected.first,
              ),
            ),
    );
  }

  AppDropdownOption<String> _userOption(OrganizationUser user) {
    final email = user.email.isEmpty ? '' : ' - ${user.email}';
    return AppDropdownOption<String>(
      value: user.userId,
      label: '${user.name}$email',
    );
  }
}

class _LeadFormActions extends StatelessWidget {
  const _LeadFormActions({required this.state});

  final LeadFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<LeadFormBloc>();
    return Align(
      alignment: Alignment.centerRight,
      child: AppButton(
        label: 'Salvar lead',
        leadingIcon: Icons.save_outlined,
        isLoading: state.isSubmitting,
        onPressed: state.isSubmitting
            ? null
            : () => bloc.add(const LeadFormSubmitted()),
      ),
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
      textInputAction: widget.textInputAction,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
    );
  }
}
