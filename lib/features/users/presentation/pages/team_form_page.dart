import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../organizations/organizations.dart';
import '../../domain/entities/organization_user.dart';
import '../bloc/team_form_bloc.dart';
import '../bloc/team_form_event.dart';
import '../bloc/team_form_state.dart';

class TeamFormPage extends StatelessWidget {
  const TeamFormPage({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    this.initialTeam,
    this.onSaved,
    super.key,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final TeamFormBloc Function() createBloc;
  final Team? initialTeam;
  final void Function(Team team)? onSaved;

  static Future<Team?> showBottomSheet({
    required BuildContext context,
    required String organizationId,
    required String userId,
    required TeamFormBloc Function() createBloc,
    Team? initialTeam,
  }) {
    return AppBottomSheet.show<Team>(
      context: context,
      title: initialTeam == null ? 'Nova equipe' : 'Editar equipe',
      closeSemanticLabel: 'Fechar formulário de equipe',
      builder: (_) => BlocProvider<TeamFormBloc>(
        create: (_) => createBloc()
          ..add(
            TeamFormStarted(
              organizationId: organizationId,
              userId: userId,
              initialTeam: initialTeam,
            ),
          ),
        child: const _TeamFormView(closeOnSuccess: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionBuilder(
      permissionService: permissionService,
      organizationId: organizationId,
      userId: userId,
      capability: Capability.teamManage,
      builder: (context, granted) {
        if (!granted) {
          return const ForbiddenPage();
        }
        return BlocProvider<TeamFormBloc>(
          create: (_) => createBloc()
            ..add(
              TeamFormStarted(
                organizationId: organizationId,
                userId: userId,
                initialTeam: initialTeam,
              ),
            ),
          child: Scaffold(
            body: AppAdminPageLayout(
              title: initialTeam == null ? 'Nova equipe' : 'Editar equipe',
              content: _TeamFormView(onSaved: onSaved),
            ),
          ),
        );
      },
    );
  }
}

class _TeamFormView extends StatelessWidget {
  const _TeamFormView({this.closeOnSuccess = false, this.onSaved});

  final bool closeOnSuccess;
  final void Function(Team team)? onSaved;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamFormBloc, TeamFormState>(
      listenWhen: (previous, current) =>
          previous.submissionStatus != current.submissionStatus,
      listener: (context, state) {
        if (state.submissionStatus == TeamFormSubmissionStatus.failure) {
          AppSnackbar.show(
            context,
            message: state.failure?.message ?? 'Revise os campos da equipe.',
            variant: AppSnackbarVariant.error,
          );
        }
        if (state.submissionStatus == TeamFormSubmissionStatus.success &&
            state.savedTeam != null) {
          onSaved?.call(state.savedTeam!);
          AppSnackbar.show(
            context,
            message: 'Equipe salva.',
            variant: AppSnackbarVariant.success,
          );
          if (closeOnSuccess) {
            Navigator.of(context).pop(state.savedTeam);
          }
        }
      },
      builder: (context, state) {
        return switch (state.loadStatus) {
          TeamFormLoadStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          TeamFormLoadStatus.failure => AppErrorState(
            title: 'Não foi possível carregar os usuários',
            message: state.failure?.message ?? 'Tente novamente em breve.',
          ),
          TeamFormLoadStatus.ready => _TeamFormContent(state: state),
        };
      },
    );
  }
}

class _TeamFormContent extends StatelessWidget {
  const _TeamFormContent({required this.state});

  final TeamFormState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TeamFormBloc>();
    final isSubmitting = state.isSubmitting;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _TeamNameField(
              name: state.name,
              isDisabled: isSubmitting,
              errorText: state.fieldErrors['name'],
              onChanged: (value) => bloc.add(TeamFormNameChanged(value)),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppDropdown<String>(
              label: 'Gestor responsável',
              hintText: 'Selecione um gestor',
              isRequired: true,
              options: state.managers.map(_userOption).toList(growable: false),
              selectedValues:
                  state.managerUserId == null || state.managerUserId!.isEmpty
                  ? const <String>{}
                  : <String>{state.managerUserId!},
              onChanged: isSubmitting
                  ? (_) {}
                  : (selected) => bloc.add(
                      TeamFormManagerSelected(
                        selected.isEmpty ? null : selected.first,
                      ),
                    ),
              closeSemanticLabel: 'Fechar seleção de gestor',
              searchHintText: 'Buscar gestor',
              noResultsLabel: 'Nenhum gestor encontrado',
              errorText: state.fieldErrors['managerUserId'],
              isDisabled: isSubmitting,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppDropdown<String>(
              label: 'Membros',
              hintText: 'Selecione vendedores ou assistentes',
              multiple: true,
              options: state.members.map(_userOption).toList(growable: false),
              selectedValues: state.memberIds,
              onChanged: isSubmitting
                  ? (_) {}
                  : (selected) => bloc.add(TeamFormMembersSelected(selected)),
              closeSemanticLabel: 'Fechar seleção de membros',
              searchHintText: 'Buscar membro',
              noResultsLabel: 'Nenhum membro encontrado',
              errorText: state.fieldErrors['memberIds'],
              isDisabled: isSubmitting,
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: state.isEditing ? 'Salvar alterações' : 'Criar equipe',
                leadingIcon: Icons.save_outlined,
                isLoading: isSubmitting,
                onPressed: isSubmitting
                    ? null
                    : () => bloc.add(const TeamFormSubmitted()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppDropdownOption<String> _userOption(OrganizationUser user) {
    final email = user.email.isEmpty ? '' : ' • ${user.email}';
    return AppDropdownOption<String>(
      value: user.userId,
      label: '${user.name}$email',
    );
  }
}

class _TeamNameField extends StatefulWidget {
  const _TeamNameField({
    required this.name,
    required this.isDisabled,
    required this.errorText,
    required this.onChanged,
  });

  final String name;
  final bool isDisabled;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  State<_TeamNameField> createState() => _TeamNameFieldState();
}

class _TeamNameFieldState extends State<_TeamNameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
  }

  @override
  void didUpdateWidget(covariant _TeamNameField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.name != _controller.text) {
      _controller.text = widget.name;
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
      label: 'Nome da equipe',
      hintText: 'Ex.: Regional Sul',
      isRequired: true,
      isDisabled: widget.isDisabled,
      errorText: widget.errorText,
      textInputAction: TextInputAction.next,
      onChanged: widget.onChanged,
    );
  }
}
