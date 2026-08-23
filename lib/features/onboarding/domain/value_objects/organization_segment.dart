/// The fashion segment an Organization operates in, collected on the
/// "Segmento" step of the onboarding wizard (TASK-038).
///
/// Stored on `Organization.settings.segment` (`OrganizationSettings`,
/// TASK-026) via [code] — never via [OrganizationSegment.name] — so renaming
/// a Dart enum member later can never silently change what is persisted.
enum OrganizationSegment { apparel, footwear, accessories, multiBrand }

extension OrganizationSegmentCode on OrganizationSegment {
  /// The normalized value persisted server-side and read back from it.
  String get code => switch (this) {
    OrganizationSegment.apparel => 'apparel',
    OrganizationSegment.footwear => 'footwear',
    OrganizationSegment.accessories => 'accessories',
    OrganizationSegment.multiBrand => 'multi_brand',
  };
}

/// Resolves [code] back into an [OrganizationSegment], or `null` when it is
/// blank/unrecognized — e.g. a value saved by a future app version this one
/// does not know about yet, or a never-completed local progress entry.
OrganizationSegment? organizationSegmentFromCode(String? code) {
  if (code == null) return null;
  for (final segment in OrganizationSegment.values) {
    if (segment.code == code) return segment;
  }
  return null;
}
