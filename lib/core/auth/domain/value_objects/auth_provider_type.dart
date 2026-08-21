/// Authentication providers VestiPro can sign a user in with.
///
/// Only [emailAndPassword] is implemented today (TASK-012). The other
/// values exist so [AuthRepository.signInWithProvider] — and its
/// implementation — can add each provider (Google, Apple, corporate SSO in
/// TASK-173) without changing the contract shape.
enum AuthProviderType { emailAndPassword, google, apple, corporateSso }
