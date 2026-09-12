enum MasterDataEntityType { customer, product, variant, price, territory }

enum DataQualityRuleType {
  requiredField,
  format,
  probableDuplicate,
  missingPrice,
  productWithoutPhoto,
  variantWithoutEan,
  customerWithoutAddress,
  customerWithoutContact,
  missingTerritory,
  invalidTaxDocument,
}

enum DataQualitySeverity { low, medium, high, critical }

enum DataQualityIssueStatus { open, assigned, fixed, dismissed, mergeRequested }

enum DuplicateMatchStrength { weak, strong }

enum MergeRequestStatus { draft, pendingApproval, approved, rejected, applied }

final class DataQualityRule {
  const DataQualityRule({
    required this.id,
    required this.organizationId,
    required this.entityType,
    required this.type,
    required this.name,
    required this.requiredFields,
    required this.enabled,
    required this.severity,
    this.pattern,
    this.weight = 10,
  });

  final String id;
  final String organizationId;
  final MasterDataEntityType entityType;
  final DataQualityRuleType type;
  final String name;
  final List<String> requiredFields;
  final bool enabled;
  final DataQualitySeverity severity;
  final String? pattern;
  final int weight;
}

final class MasterDataRecord {
  const MasterDataRecord({
    required this.id,
    required this.organizationId,
    required this.entityType,
    required this.fields,
  });

  final String id;
  final String organizationId;
  final MasterDataEntityType entityType;
  final Map<String, Object?> fields;

  String? text(String field) {
    final value = fields[field];
    return value is String ? value.trim() : null;
  }

  bool hasText(String field) => (text(field) ?? '').isNotEmpty;
}

final class DataQualityIssue {
  const DataQualityIssue({
    required this.id,
    required this.organizationId,
    required this.entityType,
    required this.entityId,
    required this.ruleId,
    required this.type,
    required this.severity,
    required this.status,
    required this.message,
    required this.detectedAt,
    this.assigneeUserId,
    this.source = 'data_quality_engine',
  });

  final String id;
  final String organizationId;
  final MasterDataEntityType entityType;
  final String entityId;
  final String ruleId;
  final DataQualityRuleType type;
  final DataQualitySeverity severity;
  final DataQualityIssueStatus status;
  final String message;
  final DateTime detectedAt;
  final String? assigneeUserId;
  final String source;
}

final class DuplicateCandidate {
  const DuplicateCandidate({
    required this.organizationId,
    required this.entityType,
    required this.leftEntityId,
    required this.rightEntityId,
    required this.score,
    required this.strength,
    required this.evidence,
  });

  final String organizationId;
  final MasterDataEntityType entityType;
  final String leftEntityId;
  final String rightEntityId;
  final double score;
  final DuplicateMatchStrength strength;
  final Map<String, String> evidence;
}

final class MergeRequest {
  const MergeRequest({
    required this.id,
    required this.organizationId,
    required this.entityType,
    required this.sourceEntityIds,
    required this.targetEntityId,
    required this.status,
    required this.impactPreview,
    required this.legacyIdMap,
    required this.requestedBy,
    required this.requestedAt,
    this.approvedBy,
    this.approvedAt,
  });

  final String id;
  final String organizationId;
  final MasterDataEntityType entityType;
  final List<String> sourceEntityIds;
  final String targetEntityId;
  final MergeRequestStatus status;
  final Map<String, int> impactPreview;
  final Map<String, String> legacyIdMap;
  final String requestedBy;
  final DateTime requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;

  bool get requiresHumanApproval => sourceEntityIds.length > 1;
}

final class MasterDataScore {
  const MasterDataScore({
    required this.organizationId,
    required this.entityType,
    required this.totalRecords,
    required this.openIssues,
    required this.score,
    required this.calculatedAt,
  });

  final String organizationId;
  final MasterDataEntityType entityType;
  final int totalRecords;
  final int openIssues;
  final double score;
  final DateTime calculatedAt;

  bool get lowConfidence => score < 80;
}

final class DataQualityEngine {
  const DataQualityEngine();

  List<DataQualityIssue> evaluate({
    required DateTime detectedAt,
    required Iterable<DataQualityRule> rules,
    required Iterable<MasterDataRecord> records,
  }) {
    final issues = <DataQualityIssue>[];
    for (final record in records) {
      final applicable = rules.where(
        (rule) =>
            rule.enabled &&
            rule.organizationId == record.organizationId &&
            rule.entityType == record.entityType,
      );
      for (final rule in applicable) {
        for (final field in rule.requiredFields) {
          if (!record.hasText(field)) {
            issues.add(
              DataQualityIssue(
                id: '${record.id}-${rule.id}-$field',
                organizationId: record.organizationId,
                entityType: record.entityType,
                entityId: record.id,
                ruleId: rule.id,
                type: rule.type,
                severity: rule.severity,
                status: DataQualityIssueStatus.open,
                message: 'Campo obrigatorio ausente: $field.',
                detectedAt: detectedAt,
              ),
            );
          }
        }
        if (rule.type == DataQualityRuleType.variantWithoutEan &&
            !record.hasText('ean')) {
          issues.add(
            DataQualityIssue(
              id: '${record.id}-${rule.id}-ean',
              organizationId: record.organizationId,
              entityType: record.entityType,
              entityId: record.id,
              ruleId: rule.id,
              type: rule.type,
              severity: rule.severity,
              status: DataQualityIssueStatus.open,
              message: 'Variante sem EAN.',
              detectedAt: detectedAt,
            ),
          );
        }
        if (rule.type == DataQualityRuleType.productWithoutPhoto &&
            (record.fields['photoCount'] as int? ?? 0) <= 0) {
          issues.add(
            DataQualityIssue(
              id: '${record.id}-${rule.id}-photo',
              organizationId: record.organizationId,
              entityType: record.entityType,
              entityId: record.id,
              ruleId: rule.id,
              type: rule.type,
              severity: rule.severity,
              status: DataQualityIssueStatus.open,
              message: 'Produto sem foto.',
              detectedAt: detectedAt,
            ),
          );
        }
      }
    }
    return issues;
  }
}

final class DuplicateDetector {
  const DuplicateDetector();

  List<DuplicateCandidate> detect(Iterable<MasterDataRecord> records) {
    final list = records.toList(growable: false);
    final candidates = <DuplicateCandidate>[];
    for (var i = 0; i < list.length; i++) {
      for (var j = i + 1; j < list.length; j++) {
        final a = list[i];
        final b = list[j];
        if (a.organizationId != b.organizationId ||
            a.entityType != b.entityType) {
          continue;
        }
        final score = _score(a, b);
        if (score >= 0.65) {
          candidates.add(
            DuplicateCandidate(
              organizationId: a.organizationId,
              entityType: a.entityType,
              leftEntityId: a.id,
              rightEntityId: b.id,
              score: score,
              strength: score >= 0.9
                  ? DuplicateMatchStrength.strong
                  : DuplicateMatchStrength.weak,
              evidence: {
                if (_norm(a.text('taxDocument')) ==
                    _norm(b.text('taxDocument')))
                  'taxDocument': 'match',
                if (_norm(a.text('name')) == _norm(b.text('name')))
                  'name': 'match',
                if (_norm(a.text('sku')) == _norm(b.text('sku')))
                  'sku': 'match',
              },
            ),
          );
        }
      }
    }
    return candidates;
  }

  double _score(MasterDataRecord a, MasterDataRecord b) {
    if (_samePresent(a.text('taxDocument'), b.text('taxDocument'))) return 1;
    if (_samePresent(a.text('sku'), b.text('sku'))) return 0.95;
    if (_samePresent(a.text('name'), b.text('name'))) return 0.7;
    return 0;
  }

  bool _samePresent(String? a, String? b) {
    final left = _norm(a);
    final right = _norm(b);
    return left != null && right != null && left == right;
  }

  String? _norm(String? value) {
    final normalized = value?.trim().toLowerCase().replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (normalized == null || normalized.isEmpty) {
      final text = value?.trim().toLowerCase();
      return text == null || text.isEmpty ? null : text;
    }
    return normalized;
  }
}

final class MergePlanner {
  const MergePlanner();

  MergeRequest plan({
    required String id,
    required DateTime requestedAt,
    required String requestedBy,
    required String organizationId,
    required MasterDataEntityType entityType,
    required String targetEntityId,
    required List<String> sourceEntityIds,
    required Map<String, int> referenceCountsByCollection,
  }) {
    return MergeRequest(
      id: id,
      organizationId: organizationId,
      entityType: entityType,
      sourceEntityIds: sourceEntityIds,
      targetEntityId: targetEntityId,
      status: MergeRequestStatus.pendingApproval,
      impactPreview: referenceCountsByCollection,
      legacyIdMap: {
        for (final sourceId in sourceEntityIds)
          if (sourceId != targetEntityId) sourceId: targetEntityId,
      },
      requestedBy: requestedBy,
      requestedAt: requestedAt,
    );
  }
}

final class MasterDataScoreCalculator {
  const MasterDataScoreCalculator();

  MasterDataScore calculate({
    required String organizationId,
    required MasterDataEntityType entityType,
    required int totalRecords,
    required Iterable<DataQualityIssue> issues,
    required DateTime calculatedAt,
  }) {
    final open = issues
        .where(
          (issue) =>
              issue.organizationId == organizationId &&
              issue.entityType == entityType &&
              issue.status != DataQualityIssueStatus.fixed &&
              issue.status != DataQualityIssueStatus.dismissed,
        )
        .length;
    final rawScore = totalRecords <= 0
        ? 100
        : 100 - (open / totalRecords * 100);
    return MasterDataScore(
      organizationId: organizationId,
      entityType: entityType,
      totalRecords: totalRecords,
      openIssues: open,
      score: rawScore.clamp(0, 100).toDouble(),
      calculatedAt: calculatedAt,
    );
  }
}

final class DataQualityVisibilityService {
  const DataQualityVisibilityService();

  bool canViewScore({required bool isOwnerOrAdmin, required bool isManager}) {
    return isOwnerOrAdmin || isManager;
  }

  bool canFixIssue({
    required bool isOwnerOrAdmin,
    required bool isManager,
    required String currentUserId,
    required DataQualityIssue issue,
  }) {
    return isOwnerOrAdmin || isManager || issue.assigneeUserId == currentUserId;
  }

  bool canApproveMerge({
    required bool isOwnerOrAdmin,
    required bool isManager,
  }) {
    return isOwnerOrAdmin || isManager;
  }
}

final class InsightConfidenceIndicator {
  const InsightConfidenceIndicator({
    required this.score,
    required this.message,
  });

  final double score;
  final String message;
}

final class InsightConfidenceService {
  const InsightConfidenceService();

  InsightConfidenceIndicator indicatorFor(MasterDataScore score) {
    if (!score.lowConfidence) {
      return InsightConfidenceIndicator(
        score: score.score,
        message: 'Confianca adequada para dashboard/insight.',
      );
    }
    return InsightConfidenceIndicator(
      score: score.score,
      message:
          'Baixa confianca: existem pendencias de qualidade cadastral que podem afetar este insight.',
    );
  }
}
