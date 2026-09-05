import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../errors/errors.dart';
import '../../../utils/utils.dart';
import '../../domain/entities/communication_preferences.dart';
import '../../domain/repositories/communication_preferences_repository.dart';
import '../datasources/communication_preferences_data_source.dart';
import '../dtos/communication_preferences_dto.dart';
import '../mappers/communication_preferences_mapper.dart';

@LazySingleton(as: CommunicationPreferencesRepository)
final class CommunicationPreferencesRepositoryImpl
    implements CommunicationPreferencesRepository {
  const CommunicationPreferencesRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final CommunicationPreferencesDataSource dataSource;
  final CommunicationPreferencesMapper mapper;

  @override
  Future<AppResult<CommunicationPreferences>> get({
    required String organizationId,
    required String userId,
  }) async {
    try {
      final dto = await dataSource.getById(
        organizationId: organizationId,
        userId: userId,
      );
      return AppSuccess<CommunicationPreferences>(
        _toEntityOrDefaults(
          dto,
          organizationId: organizationId,
          userId: userId,
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<CommunicationPreferences>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<CommunicationPreferences>(
        UnexpectedFailure(
          'Unexpected error reading communication preferences.',
          code: 'communication_preferences_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Stream<CommunicationPreferences> watch({
    required String organizationId,
    required String userId,
  }) {
    final defaults = CommunicationPreferences.defaults(
      organizationId: organizationId,
      userId: userId,
    );
    return dataSource
        .watch(organizationId: organizationId, userId: userId)
        .map(
          (dto) => _toEntityOrDefaults(
            dto,
            organizationId: organizationId,
            userId: userId,
          ),
        )
        .transform(
          StreamTransformer<
            CommunicationPreferences,
            CommunicationPreferences
          >.fromHandlers(
            handleError: (error, stackTrace, sink) {
              // A transient read/permission error must never terminate this
              // stream — the preferences screen (and every notification
              // generator gating through it) degrades to the safe default
              // instead, same "never fail closed" precedent
              // `NotificationInboxRepository.listForUser` already documents.
              sink.add(defaults);
            },
          ),
        );
  }

  @override
  Future<AppResult<CommunicationPreferences>> save({
    required CommunicationPreferences preferences,
  }) async {
    try {
      final withTimestamp = CommunicationPreferences(
        organizationId: preferences.organizationId,
        userId: preferences.userId,
        categoryPreferences: preferences.categoryPreferences,
        updatedAt: DateTime.now().toUtc(),
      );
      await dataSource.upsert(mapper.toDto(withTimestamp));
      return AppSuccess<CommunicationPreferences>(withTimestamp);
    } on AppException catch (exception) {
      return AppFailure<CommunicationPreferences>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<CommunicationPreferences>(
        UnexpectedFailure(
          'Unexpected error saving communication preferences.',
          code: 'communication_preferences_save_unexpected',
          cause: exception,
        ),
      );
    }
  }

  CommunicationPreferences _toEntityOrDefaults(
    CommunicationPreferencesDto? dto, {
    required String organizationId,
    required String userId,
  }) {
    if (dto == null) {
      return CommunicationPreferences.defaults(
        organizationId: organizationId,
        userId: userId,
      );
    }
    return mapper.toEntity(dto);
  }
}
