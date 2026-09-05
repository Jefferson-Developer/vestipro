/// A single device+user link this app has registered for Firebase Cloud
/// Messaging delivery (TASK-150) — whatever later sends a push (Cloud
/// Functions, out of this task's scope) resolves its recipients through
/// documents like this one, never by tracking FCM tokens anywhere else.
///
/// Persisted at `organizations/{organizationId}/pushDevices/{id}`, where
/// [id] is a locally-generated, stable installation id — never the FCM
/// [token] itself, which rotates over the device's lifetime (see
/// `DeviceInstallationIdProvider`). [organizationId]/[userId] together
/// scope the link to the Membership it was registered for: the same
/// physical device registers one [PushDevice] per Organization a user is
/// signed into (today, only the single active Organization `LoginBloc`
/// resolves — see `ResolveActiveOrganizationIdUseCase`'s own documented
/// single-Organization limitation), so a push aimed at Organization A never
/// reaches a device only ever linked to Organization B.
///
/// [deletedAt] marks the link invalidated (logout on this device, or a
/// user switch) without physically deleting the document — same soft-
/// delete convention as every other document `FirestoreCollectionDataSource`
/// covers.
final class PushDevice {
  const PushDevice({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.token,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.lastUsedAt,
    this.deletedAt,
  });

  final String id;
  final String organizationId;
  final String userId;
  final String token;
  final String platform;
  final String appVersion;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final DateTime? deletedAt;

  bool get isActive => deletedAt == null;
}
