import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/permissions/permissions.dart';
import '../../domain/entities/saved_report.dart';
import '../bloc/saved_reports_bloc.dart';
import '../bloc/saved_reports_event.dart';
import '../bloc/saved_reports_state.dart';

/// "Meus relatórios" / "Compartilhados comigo" (TASK-145): saved
/// `ReportDefinition`s (TASK-144) the signed-in user can re-execute with one
/// tap, rename, (re)share, duplicate or delete.
///
/// Edit/rename/share/delete actions are only ever offered for the "Meus
/// relatórios" section here — an OWNER/ADMIN editing a report shared by
/// someone else (allowed by `UpdateSavedReport`/`DeleteSavedReport` and by
/// `firestore.rules`) has no dedicated affordance in this first screen yet;
/// "Compartilhados comigo" only ever offers "Abrir".
class SavedReportsPage extends StatelessWidget {
  const SavedReportsPage({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.permissionService,
    required this.createBloc,
    required this.onOpenReportBuilder,
    super.key,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final PermissionService permissionService;
  final SavedReportsBloc Function() createBloc;
  final VoidCallback onOpenReportBuilder;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => createBloc()
      ..add(
        SavedReportsStarted(
          organizationId: organizationId,
          companyId: companyId,
          userId: userId,
        ),
      ),
    child: _SavedReportsView(
      organizationId: organizationId,
      userId: userId,
      permissionService: permissionService,
      onOpenReportBuilder: onOpenReportBuilder,
    ),
  );
}

class _SavedReportsView extends StatelessWidget {
  const _SavedReportsView({
    required this.organizationId,
    required this.userId,
    required this.permissionService,
    required this.onOpenReportBuilder,
  });

  final String organizationId;
  final String userId;
  final PermissionService permissionService;
  final VoidCallback onOpenReportBuilder;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Relatórios salvos')),
    body: BlocConsumer<SavedReportsBloc, SavedReportsState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.successMessage != current.successMessage ||
          previous.reportToOpen != current.reportToOpen,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
          context.read<SavedReportsBloc>().add(
            const SavedReportsMessageCleared(),
          );
        } else if (state.successMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.successMessage!)));
          context.read<SavedReportsBloc>().add(
            const SavedReportsMessageCleared(),
          );
        }
        if (state.reportToOpen != null) {
          context.read<SavedReportsBloc>().add(
            const SavedReportOpenedMessageCleared(),
          );
          onOpenReportBuilder();
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case SavedReportsStatus.initial:
          case SavedReportsStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case SavedReportsStatus.failure:
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.failure?.message ?? 'Não foi possível carregar.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<SavedReportsBloc>().add(
                      const SavedReportsRetried(),
                    ),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          case SavedReportsStatus.ready:
            if (state.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bookmark_border,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    const Text('Nenhuma visualização salva ainda.'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onOpenReportBuilder,
                      icon: const Icon(Icons.add),
                      label: const Text('Construir um relatório'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Meus relatórios',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (state.owned.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Você ainda não salvou nenhuma visualização.'),
                  )
                else
                  ...state.owned.map(
                    (report) => _OwnedReportTile(
                      key: ValueKey('owned-${report.id}'),
                      report: report,
                      permissionService: permissionService,
                      organizationId: organizationId,
                      userId: userId,
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Compartilhados comigo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (state.shared.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhuma visualização compartilhada com você.'),
                  )
                else
                  ...state.shared.map(
                    (report) => _SharedReportTile(
                      key: ValueKey('shared-${report.id}'),
                      report: report,
                    ),
                  ),
              ],
            );
        }
      },
    ),
  );
}

class _OwnedReportTile extends StatelessWidget {
  const _OwnedReportTile({
    required super.key,
    required this.report,
    required this.permissionService,
    required this.organizationId,
    required this.userId,
  });

  final SavedReport report;
  final PermissionService permissionService;
  final String organizationId;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<SavedReportsBloc>();
    return Card(
      child: ListTile(
        leading: IconButton(
          icon: Icon(
            report.favorite ? Icons.star : Icons.star_border,
            color: report.favorite
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          tooltip: 'Favoritar',
          onPressed: () => bloc.add(SavedReportFavoriteToggleRequested(report)),
        ),
        title: Text(report.name),
        subtitle: Text(_visibilityLabel(report.visibility)),
        onTap: () => bloc.add(SavedReportOpenRequested(report)),
        trailing: PopupMenuButton<_OwnedReportAction>(
          onSelected: (action) => _onSelected(context, action),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _OwnedReportAction.rename,
              child: Text('Renomear'),
            ),
            PopupMenuItem(
              value: _OwnedReportAction.share,
              child: Text('Compartilhamento'),
            ),
            PopupMenuItem(
              value: _OwnedReportAction.duplicate,
              child: Text('Duplicar'),
            ),
            PopupMenuItem(
              value: _OwnedReportAction.delete,
              child: Text('Excluir'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    _OwnedReportAction action,
  ) async {
    final bloc = context.read<SavedReportsBloc>();
    switch (action) {
      case _OwnedReportAction.rename:
        final newName = await _promptName(context, initial: report.name);
        if (newName != null && newName.trim().isNotEmpty) {
          bloc.add(SavedReportRenameRequested(report, newName.trim()));
        }
      case _OwnedReportAction.share:
        final visibility = await _promptVisibility(context);
        if (visibility != null) {
          bloc.add(SavedReportVisibilityChangeRequested(report, visibility));
        }
      case _OwnedReportAction.duplicate:
        final newName = await _promptName(
          context,
          initial: '${report.name} (cópia)',
        );
        if (newName != null && newName.trim().isNotEmpty) {
          bloc.add(SavedReportDuplicateRequested(report, newName.trim()));
        }
      case _OwnedReportAction.delete:
        final confirmed = await _confirmDelete(context, report.name);
        if (confirmed == true) {
          bloc.add(SavedReportDeleteRequested(report));
        }
    }
  }

  Future<String?> _promptName(BuildContext context, {required String initial}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nome da visualização'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<SavedReportVisibility?> _promptVisibility(BuildContext context) {
    return showDialog<SavedReportVisibility>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Compartilhamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Privado'),
              onTap: () => Navigator.of(
                dialogContext,
              ).pop(SavedReportVisibility.private),
            ),
            PermissionBuilder(
              permissionService: permissionService,
              organizationId: organizationId,
              userId: userId,
              capability: Capability.reportShareTeam,
              builder: (context, granted) => ListTile(
                enabled: granted,
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Minha equipe'),
                onTap: granted
                    ? () => Navigator.of(
                        dialogContext,
                      ).pop(SavedReportVisibility.team)
                    : null,
              ),
            ),
            PermissionBuilder(
              permissionService: permissionService,
              organizationId: organizationId,
              userId: userId,
              capability: Capability.reportShareOrganization,
              builder: (context, granted) => ListTile(
                enabled: granted,
                leading: const Icon(Icons.public),
                title: const Text('Toda a organização'),
                onTap: granted
                    ? () => Navigator.of(
                        dialogContext,
                      ).pop(SavedReportVisibility.organization)
                    : null,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir visualização'),
        content: Text(
          'Deseja realmente excluir "$name"? Esta ação não pode '
          'ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

enum _OwnedReportAction { rename, share, duplicate, delete }

class _SharedReportTile extends StatelessWidget {
  const _SharedReportTile({required super.key, required this.report});

  final SavedReport report;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        report.visibility == SavedReportVisibility.organization
            ? Icons.public
            : Icons.groups_outlined,
      ),
      title: Text(report.name),
      subtitle: Text(_visibilityLabel(report.visibility)),
      onTap: () => context.read<SavedReportsBloc>().add(
        SavedReportOpenRequested(report),
      ),
    ),
  );
}

String _visibilityLabel(SavedReportVisibility visibility) =>
    switch (visibility) {
      SavedReportVisibility.private => 'Privado',
      SavedReportVisibility.team => 'Compartilhado com a equipe',
      SavedReportVisibility.organization => 'Compartilhado com a organização',
    };
