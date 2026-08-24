import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/pipeline_stage.dart';
import '../../domain/repositories/pipeline_stage_repository.dart';
import '../mappers/pipeline_stage_mapper.dart';

/// Local pipeline stage store used until the remote/outbox sync
/// implementation exists (TASK-058), matching the precedent set by
/// `SharedPreferencesLeadRepository` (TASK-056): the local JSON schema is
/// intentionally independent from [PipelineStageDto] (Firestore-shaped,
/// `Timestamp` fields) — dates are stored as ISO-8601 strings here.
/// [PipelineStageMapper.terminalTypeToDto]/[PipelineStageMapper.terminalTypeToEntity]
/// are still reused so that conversion table is never duplicated.
@LazySingleton(as: PipelineStageRepository)
final class SharedPreferencesPipelineStageRepository
    implements PipelineStageRepository {
  const SharedPreferencesPipelineStageRepository(this._mapper);

  final PipelineStageMapper _mapper;

  String _keyFor(String organizationId) => 'pipeline_stages_$organizationId';

  @override
  Future<AppResult<PipelineStage>> create({
    required PipelineStage stage,
  }) async {
    try {
      final stages = await _load(stage.organizationId);
      final next = <PipelineStage>[
        ...stages.where((existing) => existing.id != stage.id),
        stage,
      ];
      await _save(stage.organizationId, next);
      return AppSuccess<PipelineStage>(stage);
    } catch (exception) {
      return AppFailure<PipelineStage>(
        UnexpectedFailure(
          'Unexpected error creating pipeline stage locally.',
          code: 'pipeline_stage_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PipelineStage>> update({
    required PipelineStage stage,
  }) async {
    try {
      final stages = await _load(stage.organizationId);
      final index = stages.indexWhere((existing) => existing.id == stage.id);
      if (index == -1) {
        return const AppFailure<PipelineStage>(
          NotFoundFailure(
            'Pipeline stage not found.',
            code: 'pipeline_stage_not_found',
          ),
        );
      }

      final next = List<PipelineStage>.of(stages)..[index] = stage;
      await _save(stage.organizationId, next);
      return AppSuccess<PipelineStage>(stage);
    } catch (exception) {
      return AppFailure<PipelineStage>(
        UnexpectedFailure(
          'Unexpected error updating pipeline stage locally.',
          code: 'pipeline_stage_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PipelineStage>>> listByOrganization({
    required String organizationId,
  }) async {
    try {
      final stages = (await _load(organizationId)).toList(growable: false)
        ..sort((a, b) => a.order.compareTo(b.order));
      return AppSuccess<List<PipelineStage>>(stages);
    } catch (exception) {
      return AppFailure<List<PipelineStage>>(
        UnexpectedFailure(
          'Unexpected error listing pipeline stages locally.',
          code: 'pipeline_stage_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PipelineStage>>> reorder({
    required String organizationId,
    required List<String> orderedStageIds,
    required String updatedBy,
  }) async {
    try {
      final stages = await _load(organizationId);
      final byId = <String, PipelineStage>{
        for (final stage in stages) stage.id: stage,
      };
      final now = DateTime.now().toUtc();
      final reordered = <PipelineStage>[
        for (var index = 0; index < orderedStageIds.length; index++)
          if (byId[orderedStageIds[index]] case final stage?)
            stage.order == index
                ? stage
                : stage.copyWith(
                    order: index,
                    updatedAt: now,
                    updatedBy: updatedBy,
                    version: stage.version + 1,
                  ),
      ];

      if (reordered.length != orderedStageIds.length) {
        return const AppFailure<List<PipelineStage>>(
          NotFoundFailure(
            'Pipeline stage not found.',
            code: 'pipeline_stage_not_found',
          ),
        );
      }

      await _save(organizationId, reordered);
      return AppSuccess<List<PipelineStage>>(reordered);
    } catch (exception) {
      return AppFailure<List<PipelineStage>>(
        UnexpectedFailure(
          'Unexpected error reordering pipeline stages locally.',
          code: 'pipeline_stage_local_reorder_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<PipelineStage>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <PipelineStage>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local pipeline stage list.',
        code: 'invalid_pipeline_stage_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local pipeline stage payload.',
              code: 'invalid_pipeline_stage_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<PipelineStage> stages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(stages.map(_toJson).toList(growable: false)),
    );
  }

  PipelineStage _fromJson(Map<String, dynamic> json) {
    return PipelineStage(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      name: _requiredString(json, 'name'),
      order: _requiredInt(json, 'order'),
      colorHex: _requiredString(json, 'colorHex'),
      terminalType: _mapper.terminalTypeToEntity(
        _requiredString(json, 'terminalType'),
      ),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      version: _requiredInt(json, 'version'),
    );
  }

  Map<String, dynamic> _toJson(PipelineStage stage) {
    return <String, dynamic>{
      'id': stage.id,
      'organizationId': stage.organizationId,
      'name': stage.name,
      'order': stage.order,
      'colorHex': stage.colorHex,
      'terminalType': _mapper.terminalTypeToDto(stage.terminalType),
      'createdAt': stage.createdAt.toUtc().toIso8601String(),
      'createdBy': stage.createdBy,
      'updatedAt': stage.updatedAt.toUtc().toIso8601String(),
      'updatedBy': stage.updatedBy,
      'version': stage.version,
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local pipeline stage string field.',
      code: 'invalid_pipeline_stage_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local pipeline stage integer field.',
      code: 'invalid_pipeline_stage_local_payload',
      cause: field,
    );
  }
}
