final class ReportQueryResult {
  const ReportQueryResult({
    required this.columns,
    required this.rows,
    required this.generatedAt,
  });

  final List<String> columns;
  final List<Map<String, Object?>> rows;
  final DateTime generatedAt;

  factory ReportQueryResult.fromJson(Map<String, dynamic> json) =>
      ReportQueryResult(
        columns: List<String>.from(json['columns'] as List),
        rows: (json['rows'] as List)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList(growable: false),
        generatedAt: DateTime.parse(json['generatedAt'] as String),
      );
}
