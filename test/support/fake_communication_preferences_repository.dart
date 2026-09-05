import 'package:vestipro/core/notifications/notifications.dart';
import 'package:vestipro/core/utils/utils.dart';

/// Minimal in-memory [CommunicationPreferencesRepository] fake (TASK-154),
/// reused by every notification-generator test that needs to construct a
/// real `ShouldDispatchNotificationUseCase` — a `final class`, so it can
/// only ever be exercised through its own real (fakeable) repository
/// dependency, never mocked/subclassed from a test file outside its own
/// library.
///
/// Defaults to [CommunicationPreferences.defaults] for any
/// `(organizationId, userId)` pair never [seed]ed — same "preferência
/// ausente tem padrão seguro" behavior the real
/// `CommunicationPreferencesRepositoryImpl` implements, so every existing
/// generator test written before TASK-154 keeps passing unchanged (the
/// default allows every category/channel except e-mail).
final class FakeCommunicationPreferencesRepository
    implements CommunicationPreferencesRepository {
  final Map<String, CommunicationPreferences> _stored =
      <String, CommunicationPreferences>{};

  String _key(String organizationId, String userId) =>
      '$organizationId::$userId';

  /// Test hook: makes [preferences] the stored value for
  /// `(preferences.organizationId, preferences.userId)`, as if the user had
  /// already saved it from some device.
  void seed(CommunicationPreferences preferences) {
    _stored[_key(preferences.organizationId, preferences.userId)] = preferences;
  }

  @override
  Future<AppResult<CommunicationPreferences>> get({
    required String organizationId,
    required String userId,
  }) async {
    return AppSuccess<CommunicationPreferences>(
      _stored[_key(organizationId, userId)] ??
          CommunicationPreferences.defaults(
            organizationId: organizationId,
            userId: userId,
          ),
    );
  }

  @override
  Stream<CommunicationPreferences> watch({
    required String organizationId,
    required String userId,
  }) async* {
    yield _stored[_key(organizationId, userId)] ??
        CommunicationPreferences.defaults(
          organizationId: organizationId,
          userId: userId,
        );
  }

  @override
  Future<AppResult<CommunicationPreferences>> save({
    required CommunicationPreferences preferences,
  }) async {
    seed(preferences);
    return AppSuccess<CommunicationPreferences>(preferences);
  }
}
