import 'package:flutter/material.dart';

import '../../domain/entities/about_app.dart';

class AboutAppContent extends StatelessWidget {
  const AboutAppContent({required this.aboutApp, super.key});

  final AboutApp aboutApp;

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
      ],
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
