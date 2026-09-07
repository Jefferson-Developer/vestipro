// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get brandTagline => 'Your sales force, your way.';

  @override
  String get emailFieldLabel => 'Email';

  @override
  String get emailFieldSemanticLabel => 'Email field';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get passwordFieldSemanticLabel => 'Password field';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get loginHeadline => 'Welcome back';

  @override
  String get loginSubtitle =>
      'Sign in with your email and password to access your accounts.';

  @override
  String get loginSubmitButton => 'Sign in';

  @override
  String get forgotPasswordLink => 'Forgot my password';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get loginCreateAccountSemanticLabel =>
      'Don\'t have an account yet? Create account';

  @override
  String get corporateSsoButton => 'Sign in with corporate SSO';

  @override
  String get signUpHeadline => 'Create your account';

  @override
  String get signUpSubtitle =>
      'Start organizing your accounts and orders in minutes.';

  @override
  String get fullNameFieldLabel => 'Full name';

  @override
  String get fullNameFieldSemanticLabel => 'Name field';

  @override
  String get inviteEmailLockedHelperText =>
      'This invitation is exclusive to this email.';

  @override
  String get passwordHelperText =>
      'At least 8 characters, with letters and numbers.';

  @override
  String get confirmPasswordFieldLabel => 'Confirm password';

  @override
  String get confirmPasswordFieldSemanticLabel => 'Confirm password field';

  @override
  String get termsAcceptanceRichPrefix => 'I have read and accept the ';

  @override
  String get termsOfServiceLinkText => 'Terms of Service and Privacy Policy';

  @override
  String get termsAcceptanceLabel =>
      'I have read and accept the Terms of Service and Privacy Policy.';

  @override
  String get termsAcceptanceSemanticLabel =>
      'I accept the Terms of Service and Privacy Policy';

  @override
  String get alreadyHaveAccountLink => 'Already have an account? Sign in';

  @override
  String get forgotPasswordHeadline => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send instructions to reset your password.';

  @override
  String get sendInstructionsButton => 'Send instructions';

  @override
  String get backToLoginLink => 'Back to sign in';

  @override
  String get passwordResetGenericMessage =>
      'If the email you entered exists in our records, you will receive instructions to reset your password.';

  @override
  String get languageSettingsTooltip => 'Language';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get languageSettingsDescription =>
      'Choose the VestiPro interface language on this device. Product names, customer names and other data are never translated — only the app\'s own text.';

  @override
  String languageSettingsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count languages available',
      one: '$count language available',
    );
    return '$_temp0';
  }

  @override
  String get languageChangedConfirmation => 'Language changed.';

  @override
  String get currentLanguageSemanticLabel => 'Current language';
}
