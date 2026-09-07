/// Outcome of trying to capture the device's current location for a single
/// visit check-in (TASK-178, EPIC-24).
///
/// Every value here is a *valid*, non-blocking outcome for the check-in
/// itself — geolocation is always complementary evidence, never a
/// requirement: `CheckInVisitUseCase` registers the check-in's CRM activity
/// regardless of which of these is produced.
enum VisitCheckInLocationStatus {
  /// The seller did not opt in to share location for this specific
  /// check-in — no permission was ever requested.
  skippedByUser,

  /// Coordinates were captured successfully.
  captured,

  /// The device denied the location permission for this request (the
  /// seller may grant it on a future check-in).
  permissionDenied,

  /// The device permanently denied the location permission (the seller
  /// would need to change it from the OS settings).
  permissionDeniedForever,

  /// The device's location service (GPS) is turned off.
  serviceDisabled,

  /// Permission was granted but the position could not be obtained in time
  /// (e.g. no signal, timeout) or an unexpected platform error occurred.
  unavailable,
}

extension VisitCheckInLocationStatusLabel on VisitCheckInLocationStatus {
  /// Short, user-facing explanation shown after a check-in without
  /// coordinates, so the seller understands why (never presented as an
  /// error/failure of the check-in itself).
  String get label {
    return switch (this) {
      VisitCheckInLocationStatus.skippedByUser =>
        'Check-in registrado sem localização.',
      VisitCheckInLocationStatus.captured => 'Localização registrada.',
      VisitCheckInLocationStatus.permissionDenied =>
        'Permissão de localização negada.',
      VisitCheckInLocationStatus.permissionDeniedForever =>
        'Permissão de localização negada permanentemente. '
            'Habilite nas configurações do dispositivo se quiser incluir '
            'localização nos próximos check-ins.',
      VisitCheckInLocationStatus.serviceDisabled =>
        'Serviço de localização desativado no dispositivo.',
      VisitCheckInLocationStatus.unavailable =>
        'Não foi possível obter a localização agora.',
    };
  }

  String get analyticsCode {
    return switch (this) {
      VisitCheckInLocationStatus.skippedByUser => 'skipped_by_user',
      VisitCheckInLocationStatus.captured => 'captured',
      VisitCheckInLocationStatus.permissionDenied => 'permission_denied',
      VisitCheckInLocationStatus.permissionDeniedForever =>
        'permission_denied_forever',
      VisitCheckInLocationStatus.serviceDisabled => 'service_disabled',
      VisitCheckInLocationStatus.unavailable => 'unavailable',
    };
  }
}
