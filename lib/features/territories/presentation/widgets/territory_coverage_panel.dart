import 'package:flutter/material.dart';

import '../../domain/territory_management.dart';

final class TerritoryCoveragePanel extends StatelessWidget {
  const TerritoryCoveragePanel({required this.dashboard, super.key});

  final TerritoryCoverageDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cobertura de carteira',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...dashboard.rows.map(
          (row) => ListTile(
            leading: Icon(_iconFor(row.status)),
            title: Text('Cliente ${row.customerId}'),
            subtitle: Text(row.reason),
            trailing: Text(_labelFor(row.status)),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(CoverageStatus status) {
    return switch (status) {
      CoverageStatus.covered => Icons.check_circle_outline,
      CoverageStatus.uncovered => Icons.person_off_outlined,
      CoverageStatus.underserved => Icons.schedule_outlined,
      CoverageStatus.highPotential => Icons.trending_up_outlined,
      CoverageStatus.conflict => Icons.warning_amber_outlined,
    };
  }

  String _labelFor(CoverageStatus status) {
    return switch (status) {
      CoverageStatus.covered => 'Coberto',
      CoverageStatus.uncovered => 'Descoberto',
      CoverageStatus.underserved => 'Subatendido',
      CoverageStatus.highPotential => 'Alto potencial',
      CoverageStatus.conflict => 'Conflito',
    };
  }
}
