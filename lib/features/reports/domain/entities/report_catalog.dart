enum ReportFieldType { dimension, metric, filter }

enum ReportValueType { text, number, currency, percentage, date }

final class ReportFieldDefinition {
  const ReportFieldDefinition({
    required this.id,
    required this.label,
    required this.type,
    required this.valueType,
    this.compatibleDimensions = const <String>[],
    this.isSensitive = false,
    this.isAvailable = true,
    this.unavailableReason,
  });

  final String id;
  final String label;
  final ReportFieldType type;
  final ReportValueType valueType;
  final List<String> compatibleDimensions;
  final bool isSensitive;
  final bool isAvailable;
  final String? unavailableReason;

  factory ReportFieldDefinition.fromJson(Map<String, dynamic> json) =>
      ReportFieldDefinition(
        id: json['id'] as String,
        label: json['label'] as String,
        type: ReportFieldType.values.byName(json['type'] as String),
        valueType: ReportValueType.values.byName(json['valueType'] as String),
        compatibleDimensions: List<String>.from(
          json['compatibleDimensions'] as List? ?? const [],
        ),
        isSensitive: json['isSensitive'] as bool? ?? false,
        isAvailable: json['isAvailable'] as bool? ?? true,
        unavailableReason: json['unavailableReason'] as String?,
      );
}

final class ReportCatalog {
  const ReportCatalog({
    required this.fields,
    this.maxDimensions = 2,
    this.maxMetrics = 6,
  });

  final List<ReportFieldDefinition> fields;
  final int maxDimensions;
  final int maxMetrics;

  List<ReportFieldDefinition> get dimensions => fields
      .where(
        (field) => field.type == ReportFieldType.dimension && field.isAvailable,
      )
      .toList(growable: false);
  List<ReportFieldDefinition> get metrics => fields
      .where(
        (field) => field.type == ReportFieldType.metric && field.isAvailable,
      )
      .toList(growable: false);
  List<ReportFieldDefinition> get filters => fields
      .where(
        (field) => field.type == ReportFieldType.filter && field.isAvailable,
      )
      .toList(growable: false);

  ReportFieldDefinition? find(String id) {
    for (final field in fields) {
      if (field.id == id) return field;
    }
    return null;
  }

  factory ReportCatalog.fromJson(Map<String, dynamic> json) => ReportCatalog(
    fields: (json['fields'] as List)
        .map(
          (item) => ReportFieldDefinition.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false),
    maxDimensions: (json['maxDimensions'] as num?)?.toInt() ?? 2,
    maxMetrics: (json['maxMetrics'] as num?)?.toInt() ?? 6,
  );
}
