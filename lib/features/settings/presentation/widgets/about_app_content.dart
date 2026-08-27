import 'package:flutter/material.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/about_app.dart';
import '../../domain/entities/about_app_data_origin.dart';
import '../../domain/entities/about_app_note.dart';
import '../bloc/about_app_state.dart';

class AboutAppContent extends StatelessWidget {
  const AboutAppContent({
    required this.aboutApp,
    required this.notes,
    required this.query,
    required this.hasMore,
    required this.dataOrigin,
    required this.isLoadingNextPage,
    required this.submissionStatus,
    required this.onSearchChanged,
    required this.onLoadMore,
    required this.onSubmitDiagnostics,
    this.submissionFailure,
    super.key,
  });

  final AboutApp aboutApp;
  final List<AboutAppNote> notes;
  final String query;
  final bool hasMore;
  final AboutAppDataOrigin dataOrigin;
  final bool isLoadingNextPage;
  final AboutAppSubmissionStatus submissionStatus;
  final Failure? submissionFailure;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLoadMore;
  final VoidCallback onSubmitDiagnostics;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(aboutApp.name, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Referencia de arquitetura feature-first do VestiPro.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        _InfoRow(
          icon: Icons.new_releases_outlined,
          label: 'Versao',
          value: aboutApp.version.displayValue,
        ),
        _InfoRow(
          icon: Icons.layers_outlined,
          label: 'Ambiente',
          value: aboutApp.environmentLabel,
        ),
        _InfoRow(
          icon: Icons.update_outlined,
          label: 'Atualizado',
          value: aboutApp.updatedAt.toIso8601String(),
        ),
        _InfoRow(
          icon: Icons.storage_outlined,
          label: 'Origem',
          value: _formatDataOrigin(dataOrigin),
        ),
        const SizedBox(height: 24),
        TextField(
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Filtrar notas',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text('Notas de arquitetura', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (notes.isEmpty)
          Text(
            query.isEmpty
                ? 'Nenhuma nota disponivel.'
                : 'Nenhuma nota encontrada.',
          )
        else
          ...notes.map(_ArchitectureNoteTile.new),
        if (hasMore) ...<Widget>[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: isLoadingNextPage ? null : onLoadMore,
              icon: isLoadingNextPage
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more),
              label: const Text('Carregar mais'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: submissionStatus == AboutAppSubmissionStatus.submitting
              ? null
              : onSubmitDiagnostics,
          icon: const Icon(Icons.bug_report_outlined),
          label: Text(_formatSubmissionStatus(submissionStatus)),
        ),
        if (submissionFailure != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            submissionFailure!.message,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _ArchitectureNoteTile extends StatelessWidget {
  const _ArchitectureNoteTile(this.note);

  final AboutAppNote note;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(note.title, style: textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(note.description),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDataOrigin(AboutAppDataOrigin origin) {
  return switch (origin) {
    AboutAppDataOrigin.localCache => 'Cache local',
    AboutAppDataOrigin.remoteSynced => 'Remoto sincronizado',
  };
}

String _formatSubmissionStatus(AboutAppSubmissionStatus status) {
  return switch (status) {
    AboutAppSubmissionStatus.idle => 'Enviar diagnostico',
    AboutAppSubmissionStatus.submitting => 'Enviando...',
    AboutAppSubmissionStatus.submitted => 'Diagnostico enviado',
    AboutAppSubmissionStatus.failure => 'Tentar novamente',
  };
}
