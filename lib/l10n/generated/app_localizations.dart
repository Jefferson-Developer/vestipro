import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Frase de marca exibida no painel lateral das telas de autenticação (login, cadastro).
  ///
  /// In pt, this message translates to:
  /// **'A força de vendas do seu jeito.'**
  String get brandTagline;

  /// Rótulo do campo de e-mail, reutilizado em login, cadastro e recuperação de senha.
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get emailFieldLabel;

  /// Rótulo de acessibilidade (leitor de tela) do campo de e-mail.
  ///
  /// In pt, this message translates to:
  /// **'Campo de e-mail'**
  String get emailFieldSemanticLabel;

  /// Rótulo do campo de senha.
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get passwordFieldLabel;

  /// Rótulo de acessibilidade do campo de senha.
  ///
  /// In pt, this message translates to:
  /// **'Campo de senha'**
  String get passwordFieldSemanticLabel;

  /// Tooltip do botão que revela a senha digitada.
  ///
  /// In pt, this message translates to:
  /// **'Mostrar senha'**
  String get showPasswordTooltip;

  /// Tooltip do botão que oculta a senha digitada.
  ///
  /// In pt, this message translates to:
  /// **'Ocultar senha'**
  String get hidePasswordTooltip;

  /// Título da tela de login.
  ///
  /// In pt, this message translates to:
  /// **'Bem-vindo de volta'**
  String get loginHeadline;

  /// Subtítulo da tela de login.
  ///
  /// In pt, this message translates to:
  /// **'Entre com seu e-mail e senha para acessar sua carteira.'**
  String get loginSubtitle;

  /// Botão de envio do formulário de login.
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginSubmitButton;

  /// Link para a tela de recuperação de senha.
  ///
  /// In pt, this message translates to:
  /// **'Esqueci minha senha'**
  String get forgotPasswordLink;

  /// Botão/link para criar uma nova conta — usado tanto como link na tela de login quanto como botão de envio na tela de cadastro.
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get createAccountButton;

  /// Rótulo de acessibilidade do link "Criar conta" na tela de login.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tem conta? Criar conta'**
  String get loginCreateAccountSemanticLabel;

  /// Botão que abre o modal de login via SSO corporativo (SAML/OIDC).
  ///
  /// In pt, this message translates to:
  /// **'Entrar com SSO corporativo'**
  String get corporateSsoButton;

  /// Título da tela de cadastro.
  ///
  /// In pt, this message translates to:
  /// **'Crie sua conta'**
  String get signUpHeadline;

  /// Subtítulo da tela de cadastro.
  ///
  /// In pt, this message translates to:
  /// **'Comece a organizar sua carteira e seus pedidos em minutos.'**
  String get signUpSubtitle;

  /// Rótulo do campo de nome completo no cadastro.
  ///
  /// In pt, this message translates to:
  /// **'Nome completo'**
  String get fullNameFieldLabel;

  /// Rótulo de acessibilidade do campo de nome completo.
  ///
  /// In pt, this message translates to:
  /// **'Campo de nome'**
  String get fullNameFieldSemanticLabel;

  /// Texto de ajuda exibido quando o e-mail do cadastro está travado por um convite.
  ///
  /// In pt, this message translates to:
  /// **'Este convite é exclusivo para este e-mail.'**
  String get inviteEmailLockedHelperText;

  /// Texto de ajuda sobre os requisitos de senha no cadastro.
  ///
  /// In pt, this message translates to:
  /// **'Mínimo de 8 caracteres, com letras e números.'**
  String get passwordHelperText;

  /// Rótulo do campo de confirmação de senha.
  ///
  /// In pt, this message translates to:
  /// **'Confirmar senha'**
  String get confirmPasswordFieldLabel;

  /// Rótulo de acessibilidade do campo de confirmação de senha.
  ///
  /// In pt, this message translates to:
  /// **'Campo de confirmação de senha'**
  String get confirmPasswordFieldSemanticLabel;

  /// Trecho inicial (não clicável) do texto de aceite dos termos, antes do link.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito os '**
  String get termsAcceptanceRichPrefix;

  /// Trecho clicável (link) do texto de aceite dos termos, e também o rótulo completo usado no checkbox/label de acessibilidade.
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso e a Política de Privacidade'**
  String get termsOfServiceLinkText;

  /// Rótulo completo do checkbox de aceite dos Termos de Uso e Política de Privacidade.
  ///
  /// In pt, this message translates to:
  /// **'Li e aceito os Termos de Uso e a Política de Privacidade.'**
  String get termsAcceptanceLabel;

  /// Rótulo de acessibilidade do checkbox de aceite dos termos.
  ///
  /// In pt, this message translates to:
  /// **'Aceito os Termos de Uso e a Política de Privacidade'**
  String get termsAcceptanceSemanticLabel;

  /// Link para voltar à tela de login a partir do cadastro.
  ///
  /// In pt, this message translates to:
  /// **'Já tem conta? Entrar'**
  String get alreadyHaveAccountLink;

  /// Título da tela de recuperação de senha.
  ///
  /// In pt, this message translates to:
  /// **'Recuperar senha'**
  String get forgotPasswordHeadline;

  /// Subtítulo da tela de recuperação de senha.
  ///
  /// In pt, this message translates to:
  /// **'Informe seu e-mail e enviaremos as instruções para redefinir sua senha.'**
  String get forgotPasswordSubtitle;

  /// Botão de envio do formulário de recuperação de senha.
  ///
  /// In pt, this message translates to:
  /// **'Enviar instruções'**
  String get sendInstructionsButton;

  /// Link para voltar à tela de login.
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o login'**
  String get backToLoginLink;

  /// Mensagem única exibida após solicitar a redefinição de senha, independente de o e-mail existir ou não na base (evita enumeração de contas).
  ///
  /// In pt, this message translates to:
  /// **'Se o e-mail informado existir em nossa base, você receberá instruções para redefinir sua senha.'**
  String get passwordResetGenericMessage;

  /// Tooltip do atalho de idioma na barra superior de "Sobre o app".
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageSettingsTooltip;

  /// Título da tela de seleção de idioma.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageSettingsTitle;

  /// Texto explicativo da tela de seleção de idioma.
  ///
  /// In pt, this message translates to:
  /// **'Escolha o idioma da interface do VestiPro neste dispositivo. Nomes de produtos, clientes e outros dados nunca são traduzidos — apenas os textos do aplicativo.'**
  String get languageSettingsDescription;

  /// Contagem de idiomas disponíveis, exibida na tela de seleção de idioma.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, one{{count} idioma disponível} other{{count} idiomas disponíveis}}'**
  String languageSettingsAvailableCount(int count);

  /// Mensagem de confirmação exibida após trocar o idioma da interface.
  ///
  /// In pt, this message translates to:
  /// **'Idioma alterado.'**
  String get languageChangedConfirmation;

  /// Rótulo de acessibilidade indicando qual idioma está selecionado atualmente.
  ///
  /// In pt, this message translates to:
  /// **'Idioma atual'**
  String get currentLanguageSemanticLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
