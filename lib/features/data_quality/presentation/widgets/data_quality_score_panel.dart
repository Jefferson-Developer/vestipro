import 'package:flutter/material.dart';

import '../../domain/data_quality_governance.dart';

final class DataQualityScorePanel extends StatelessWidget {
  const DataQualityScorePanel({
    required this.score,
    required this.issues,
    super.key,
  });

  final MasterDataScore score;
  final List<DataQualityIssue> issues;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Qualidade cadastral',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(value: score.score / 100),
        const SizedBox(height: 8),
        Text(
          '${score.score.toStringAsFixed(0)}% - ${score.openIssues} pendencia(s) abertas',
        ),
        const SizedBox(height: 12),
        ...issues.map(
          (issue) => ListTile(
            leading: Icon(_iconFor(issue.severity)),
            title: Text(issue.message),
            subtitle: Text(issue.source),
          ),
        ),
      ],
    );
  }

  IconData _iconFor(DataQualitySeverity severity) {
    return switch (severity) {
      DataQualitySeverity.low => Icons.info_outline,
      DataQualitySeverity.medium => Icons.rule_folder_outlined,
      DataQualitySeverity.high => Icons.warning_amber_outlined,
      DataQualitySeverity.critical => Icons.error_outline,
    };
  }
}
