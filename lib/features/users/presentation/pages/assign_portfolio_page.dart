import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/widgets/forbidden_page.dart';
import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/commercial_team.dart';
import '../../domain/entities/organization_user.dart';
import '../../domain/entities/portfolio_assignment.dart';
import '../bloc/assign_portfolio_bloc.dart';
import '../bloc/assign_portfolio_event.dart';
import '../bloc/assign_portfolio_state.dart';

class AssignPortfolioPage extends StatelessWidget {
  const AssignPortfolioPage({
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
  final AssignPortfolioBloc Function() createBloc;

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
        return BlocProvider<AssignPortfolioBloc>(
          create: (_) => createBloc()
            ..add(
              AssignPortfolioStarted(
                organizationId: organizationId,
                companyId: companyId,
                userId: userId,
              ),
            ),
          child: const _AssignPortfolioView(),
        );
      },
    );
  }
}

class _AssignPortfolioView extends StatelessWidget {
  const _AssignPortfolioView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AssignPortfolioBloc, AssignPortfolioState>(
        listenWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus,
        listener: (context, state) {
          if (state.submissionStatus ==
              AssignPortfolioSubmissionStatus.success) {
            AppSnackbar.show(
              context,
              message: 'Vínculo de carteira salvo.',
              variant: AppSnackbarVariant.success,
            );
          }
          if (state.submissionStatus ==
              AssignPortfolioSubmissionStatus.failure) {
            AppSnackbar.show(
              context,
              message:
                  state.failure?.message ??
                  'Não foi possível salvar o vínculo.',
              variant: AppSnackbarVariant.error,
            );
          }
        },
        builder: (context, state) {
          return AppAdminPageLayout(
            title: 'Vínculo de carteira',
            content: switch (state.loadStatus) {
              AssignPortfolioLoadStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              AssignPortfolioLoadStatus.failure => AppErrorState(
                title: 'Não foi possível carregar a carteira',
                message: state.failure?.message ?? 'Tente novamente em breve.',
                retryLabel: 'Tentar novamente',
                onRetry: () => context.read<AssignPortfolioBloc>().add(
                  const AssignPortfolioRefreshRequested(),
                ),
              ),
              AssignPortfolioLoadStatus.ready => _AssignPortfolioContent(
                state: state,
              ),
            },
          );
        },
      ),
    );
  }
}

class _AssignPortfolioContent extends StatelessWidget {
  const _AssignPortfolioContent({required this.state});

  final AssignPortfolioState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _AssignmentForm(state: state),
          const SizedBox(height: AppSpacing.spacing24),
          _AssignmentTable(state: state),
        ],
      ),
    );
  }
}

class _AssignmentForm extends StatelessWidget {
  const _AssignmentForm({required this.state});

  final AssignPortfolioState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AssignPortfolioBloc>();
    final isSubmitting = state.isSubmitting;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: AppSpacing.spacing16,
            runSpacing: AppSpacing.spacing16,
            children: <Widget>[
              SizedBox(
                width: 360,
                child: AppDropdown<String>(
                  label: 'Vendedor',
                  hintText: 'Selecione um vendedor',
                  isRequired: true,
                  options: state.sellers.map(_sellerOption).toList(),
                  selectedValues:
                      state.selectedUserId == null ||
                          state.selectedUserId!.isEmpty
                      ? const <String>{}
                      : <String>{state.selectedUserId!},
                  onChanged: isSubmitting
                      ? (_) {}
                      : (selected) => bloc.add(
                          AssignPortfolioSellerSelected(
                            selected.isEmpty ? null : selected.first,
                          ),
                        ),
                  closeSemanticLabel: 'Fechar seleção de vendedor',
                  searchHintText: 'Buscar vendedor',
                  noResultsLabel: 'Nenhum vendedor encontrado',
                  errorText: state.fieldErrors['userId'],
                  isDisabled: isSubmitting,
                ),
              ),
              SizedBox(
                width: 360,
                child: AppDropdown<String>(
                  label: 'Equipe',
                  hintText: 'Selecione a equipe',
                  isRequired: true,
                  options: state.teams.map(_teamOption).toList(),
                  selectedValues:
                      state.selectedTeamId == null ||
                          state.selectedTeamId!.isEmpty
                      ? const <String>{}
                      : <String>{state.selectedTeamId!},
                  onChanged: isSubmitting
                      ? (_) {}
                      : (selected) => bloc.add(
                          AssignPortfolioTeamSelected(
                            selected.isEmpty ? null : selected.first,
                          ),
                        ),
                  closeSemanticLabel: 'Fechar seleção de equipe',
                  searchHintText: 'Buscar equipe',
                  noResultsLabel: 'Nenhuma equipe encontrada',
                  errorText: state.fieldErrors['teamId'],
                  isDisabled: isSubmitting,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing16),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<PortfolioAssignmentScopeType>(
              segments: const <ButtonSegment<PortfolioAssignmentScopeType>>[
                ButtonSegment<PortfolioAssignmentScopeType>(
                  value: PortfolioAssignmentScopeType.customer,
                  icon: Icon(Icons.person_pin_circle_outlined),
                  label: Text('Cliente'),
                ),
                ButtonSegment<PortfolioAssignmentScopeType>(
                  value: PortfolioAssignmentScopeType.criteria,
                  icon: Icon(Icons.tune_outlined),
                  label: Text('Critério'),
                ),
              ],
              selected: <PortfolioAssignmentScopeType>{state.scopeType},
              onSelectionChanged: isSubmitting
                  ? null
                  : (selected) => bloc.add(
                      AssignPortfolioScopeTypeChanged(selected.first),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          if (state.scopeType == PortfolioAssignmentScopeType.customer)
            SizedBox(
              width: 420,
              child: AppTextField(
                label: 'ID do cliente',
                hintText: 'Ex.: customer-123',
                isRequired: true,
                errorText: state.fieldErrors['customerId'],
                isDisabled: isSubmitting,
                textInputAction: TextInputAction.done,
                onChanged: (value) =>
                    bloc.add(AssignPortfolioCustomerIdChanged(value)),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.spacing16,
              runSpacing: AppSpacing.spacing16,
              children: <Widget>[
                SizedBox(
                  width: 320,
                  child: AppTextField(
                    label: 'Região',
                    hintText: 'Ex.: Sul',
                    errorText:
                        state.fieldErrors['region'] ??
                        state.fieldErrors['criteria'],
                    isDisabled: isSubmitting,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) =>
                        bloc.add(AssignPortfolioRegionChanged(value)),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: AppTextField(
                    label: 'Segmento',
                    hintText: 'Ex.: Varejo premium',
                    errorText: state.fieldErrors['segment'],
                    isDisabled: isSubmitting,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) =>
                        bloc.add(AssignPortfolioSegmentChanged(value)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.spacing24),
          Align(
            alignment: Alignment.centerRight,
            child: AppButton(
              label: 'Salvar vínculo',
              leadingIcon: Icons.save_outlined,
              isLoading: isSubmitting,
              onPressed: isSubmitting
                  ? null
                  : () => bloc.add(const AssignPortfolioSubmitted()),
            ),
          ),
        ],
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

  AppDropdownOption<String> _teamOption(CommercialTeam team) {
    return AppDropdownOption<String>(
      value: team.id,
      label: '${team.name} • ${team.managerName}',
    );
  }
}

class _AssignmentTable extends StatelessWidget {
  const _AssignmentTable({required this.state});

  final AssignPortfolioState state;

  @override
  Widget build(BuildContext context) {
    return AppDataTable<PortfolioAssignment>(
      status: state.assignments.isEmpty
          ? AppDataTableStatus.empty
          : AppDataTableStatus.idle,
      rows: state.assignments,
      rowIdBuilder: (assignment) => assignment.id,
      emptyTitle: 'Nenhum vínculo ativo',
      emptyDescription:
          'Cadastre o primeiro vínculo por ID de cliente ou critério.',
      mobileCardTitleBuilder: (context, assignment) =>
          Text(_sellerName(assignment.userId)),
      columns: <AppDataColumn<PortfolioAssignment>>[
        AppDataColumn<PortfolioAssignment>(
          label: 'Vendedor',
          cellBuilder: (context, assignment) =>
              Text(_sellerName(assignment.userId)),
        ),
        AppDataColumn<PortfolioAssignment>(
          label: 'Equipe',
          cellBuilder: (context, assignment) =>
              Text(_teamName(assignment.teamId)),
        ),
        AppDataColumn<PortfolioAssignment>(
          label: 'Escopo',
          cellBuilder: (context, assignment) => Text(assignment.scope.label),
        ),
        AppDataColumn<PortfolioAssignment>(
          label: 'Atualizado em',
          cellBuilder: (context, assignment) =>
              Text(_dateLabel(assignment.updatedAt)),
        ),
      ],
    );
  }

  String _sellerName(String userId) {
    for (final user in state.users) {
      if (user.userId == userId) return user.name;
    }
    return userId;
  }

  String _teamName(String teamId) {
    for (final team in state.teams) {
      if (team.id == teamId) return team.name;
    }
    return teamId;
  }

  String _dateLabel(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month/${local.year}';
  }
}
