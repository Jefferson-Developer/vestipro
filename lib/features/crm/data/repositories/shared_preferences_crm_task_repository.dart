import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/crm_task.dart';
import '../../domain/repositories/crm_task_repository.dart';
import '../../domain/value_objects/crm_task_status.dart';
import '../mappers/crm_task_mapper.dart';

@LazySingleton(as: CrmTaskRepository)
final class SharedPreferencesCrmTaskRepository implements CrmTaskRepository {
  const SharedPreferencesCrmTaskRepository(this._mapper);

  final CrmTaskMapper _mapper;

  String _keyFor(String organizationId) => 'crm_tasks_$organizationId';

  @override
  Future<AppResult<CrmTask>> create({required CrmTask task}) async {
    try {
      final tasks = await _load(task.organizationId);
      final next = <CrmTask>[
        ...tasks.where((existing) => existing.id != task.id),
        task,
      ];
      await _save(task.organizationId, next);
      return AppSuccess<CrmTask>(task);
    } catch (exception) {
      return AppFailure<CrmTask>(
        UnexpectedFailure(
          'Unexpected error saving CRM task locally.',
          code: 'crm_task_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CrmTask>> update({required CrmTask task}) async {
    try {
      final tasks = await _load(task.organizationId);
      final index = tasks.indexWhere((existing) => existing.id == task.id);
      if (index == -1) {
        return const AppFailure<CrmTask>(
          NotFoundFailure('CRM task not found.', code: 'crm_task_not_found'),
        );
      }
      final next = List<CrmTask>.of(tasks)..[index] = task;
      await _save(task.organizationId, next);
      return AppSuccess<CrmTask>(task);
    } catch (exception) {
      return AppFailure<CrmTask>(
        UnexpectedFailure(
          'Unexpected error updating CRM task locally.',
          code: 'crm_task_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CrmTask>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final tasks = await _load(organizationId);
      for (final task in tasks) {
        if (task.id == id) return AppSuccess<CrmTask>(task);
      }
      return const AppFailure<CrmTask>(
        NotFoundFailure('CRM task not found.', code: 'crm_task_not_found'),
      );
    } catch (exception) {
      return AppFailure<CrmTask>(
        UnexpectedFailure(
          'Unexpected error loading CRM task locally.',
          code: 'crm_task_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<CrmTask>>> listPending({
    required String organizationId,
    Set<String> responsibleUserIds = const <String>{},
    DateTime? dueBefore,
  }) async {
    try {
      final dueLimit = dueBefore?.toUtc();
      final tasks =
          (await _load(organizationId))
              .where(
                (task) =>
                    task.status == CrmTaskStatus.pending &&
                    (responsibleUserIds.isEmpty ||
                        responsibleUserIds.contains(task.responsibleUserId)) &&
                    (dueLimit == null || task.dueAt.isBefore(dueLimit)),
              )
              .toList(growable: false)
            ..sort(_compareTasks);
      return AppSuccess<List<CrmTask>>(tasks);
    } catch (exception) {
      return AppFailure<List<CrmTask>>(
        UnexpectedFailure(
          'Unexpected error listing CRM tasks locally.',
          code: 'crm_task_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  int _compareTasks(CrmTask first, CrmTask second) {
    final byDueDate = first.dueAt.compareTo(second.dueAt);
    if (byDueDate != 0) return byDueDate;
    return first.id.compareTo(second.id);
  }

  Future<List<CrmTask>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <CrmTask>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local CRM task list.',
        code: 'invalid_crm_task_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local CRM task payload.',
              code: 'invalid_crm_task_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<CrmTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(tasks.map(_toJson).toList(growable: false)),
    );
  }

  CrmTask _fromJson(Map<String, dynamic> json) {
    return CrmTask(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      companyId: _optionalString(json, 'companyId'),
      title: _requiredString(json, 'title'),
      description: _optionalString(json, 'description'),
      customerId: _optionalString(json, 'customerId'),
      leadId: _optionalString(json, 'leadId'),
      opportunityId: _optionalString(json, 'opportunityId'),
      activityId: _optionalString(json, 'activityId'),
      responsibleUserId: _requiredString(json, 'responsibleUserId'),
      dueAt: _requiredDate(json, 'dueAt'),
      priority: _mapper.priorityToEntity(_requiredString(json, 'priority')),
      status: _mapper.statusToEntity(_requiredString(json, 'status')),
      completedAt: _optionalDate(json, 'completedAt'),
      previousDueDates: _dateList(json, 'previousDueDates'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      version: _requiredInt(json, 'version'),
      syncStatus: _mapper.syncStatusToEntity(
        _requiredString(json, 'syncStatus'),
      ),
    );
  }

  Map<String, dynamic> _toJson(CrmTask task) {
    return <String, dynamic>{
      'id': task.id,
      'organizationId': task.organizationId,
      if (task.companyId != null) 'companyId': task.companyId,
      'title': task.title,
      if (task.description != null) 'description': task.description,
      if (task.customerId != null) 'customerId': task.customerId,
      if (task.leadId != null) 'leadId': task.leadId,
      if (task.opportunityId != null) 'opportunityId': task.opportunityId,
      if (task.activityId != null) 'activityId': task.activityId,
      'responsibleUserId': task.responsibleUserId,
      'dueAt': task.dueAt.toUtc().toIso8601String(),
      'priority': _mapper.priorityToDto(task.priority),
      'status': _mapper.statusToDto(task.status),
      if (task.completedAt != null)
        'completedAt': task.completedAt!.toUtc().toIso8601String(),
      'previousDueDates': task.previousDueDates
          .map((date) => date.toUtc().toIso8601String())
          .toList(growable: false),
      'createdAt': task.createdAt.toUtc().toIso8601String(),
      'createdBy': task.createdBy,
      'updatedAt': task.updatedAt.toUtc().toIso8601String(),
      'updatedBy': task.updatedBy,
      'version': task.version,
      'syncStatus': _mapper.syncStatusToDto(task.syncStatus),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local CRM task string field.',
      code: 'invalid_crm_task_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local CRM task string field.',
      code: 'invalid_crm_task_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local CRM task integer field.',
      code: 'invalid_crm_task_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = _optionalString(json, field);
    return value == null ? null : DateTime.parse(value).toUtc();
  }

  List<DateTime> _dateList(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return const <DateTime>[];
    if (value is List<dynamic> && value.every((item) => item is String)) {
      return value
          .cast<String>()
          .map((date) => DateTime.parse(date).toUtc())
          .toList(growable: false);
    }
    throw ValidationException(
      'Invalid local CRM task date list field.',
      code: 'invalid_crm_task_local_payload',
      cause: field,
    );
  }
}
