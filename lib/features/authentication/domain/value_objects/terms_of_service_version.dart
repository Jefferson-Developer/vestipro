/// Version identifier of the Terms of Service/Privacy Policy the sign-up
/// checkbox (TASK-035) records consent against.
///
/// The actual terms *content* is TASK-156's responsibility (EPIC-20); this
/// version string only needs to change whenever that content changes, so a
/// future consent audit can tell exactly which wording a given
/// [UserProfile.termsVersion] refers to.
const String kCurrentTermsOfServiceVersion = '2026-08-23';
