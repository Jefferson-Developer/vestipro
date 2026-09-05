import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/consent_record.dart';
import '../repositories/consent_repository.dart';

final class GrantConsent {
  const GrantConsent(this._repository);
  final ConsentRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
    required ConsentPurpose purpose,
    required DateTime grantedAt,
  }) => _write(
    organizationId: organizationId,
    userId: userId,
    purpose: purpose,
    granted: true,
    recordedAt: grantedAt,
  );

  Future<AppResult<void>> _write({
    required String organizationId,
    required String userId,
    required ConsentPurpose purpose,
    required bool granted,
    required DateTime recordedAt,
  }) {
    if (organizationId.trim().isEmpty || userId.trim().isEmpty) {
      return Future<AppResult<void>>.value(
        const AppFailure<void>(
          ValidationFailure(
            'Organização e usuário são obrigatórios.',
            code: 'invalid_consent_scope',
          ),
        ),
      );
    }
    return _repository.appendConsentRecord(
      ConsentRecord(
        organizationId: organizationId,
        userId: userId,
        purpose: purpose,
        granted: granted,
        recordedAt: recordedAt.toUtc(),
      ),
    );
  }
}

final class RevokeConsent {
  const RevokeConsent(this._repository);
  final ConsentRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
    required ConsentPurpose purpose,
    required DateTime revokedAt,
  }) {
    if (organizationId.trim().isEmpty || userId.trim().isEmpty) {
      return Future<AppResult<void>>.value(
        const AppFailure<void>(
          ValidationFailure(
            'Organização e usuário são obrigatórios.',
            code: 'invalid_consent_scope',
          ),
        ),
      );
    }
    return _repository.appendConsentRecord(
      ConsentRecord(
        organizationId: organizationId,
        userId: userId,
        purpose: purpose,
        granted: false,
        recordedAt: revokedAt.toUtc(),
      ),
    );
  }
}

final class ListUserConsents {
  const ListUserConsents(this._repository);
  final ConsentRepository _repository;

  Future<AppResult<List<ConsentRecord>>> call({
    required String organizationId,
    required String userId,
  }) => _repository.listUserConsents(
    organizationId: organizationId,
    userId: userId,
  );
}

/// The latest immutable event is the effective decision for each purpose.
Map<ConsentPurpose, ConsentRecord> effectiveConsents(
  Iterable<ConsentRecord> records,
) {
  final effective = <ConsentPurpose, ConsentRecord>{};
  for (final record in records) {
    final current = effective[record.purpose];
    if (current == null || record.recordedAt.isAfter(current.recordedAt)) {
      effective[record.purpose] = record;
    }
  }
  return effective;
}

/// Reactive gate for consent-dependent capabilities such as geolocation.
/// Consumers must subscribe for their whole active lifetime so a revocation
/// turns the capability off immediately, without waiting for another login.
final class WatchConsentAccess {
  const WatchConsentAccess(this._repository);
  final ConsentRepository _repository;

  Stream<AppResult<bool>> call({
    required String organizationId,
    required String userId,
    required ConsentPurpose purpose,
  }) => _repository
      .watchUserConsents(organizationId: organizationId, userId: userId)
      .map(
        (result) => result.fold<AppResult<bool>>(
          onSuccess: (records) => AppSuccess<bool>(
            effectiveConsents(records)[purpose]?.granted ?? false,
          ),
          onFailure: AppFailure<bool>.new,
        ),
      );
}
