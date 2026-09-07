// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get brandTagline => 'A força de vendas do seu jeito.';

  @override
  String get emailFieldLabel => 'E-mail';

  @override
  String get emailFieldSemanticLabel => 'Campo de e-mail';

  @override
  String get passwordFieldLabel => 'Senha';

  @override
  String get passwordFieldSemanticLabel => 'Campo de senha';

  @override
  String get showPasswordTooltip => 'Mostrar senha';

  @override
  String get hidePasswordTooltip => 'Ocultar senha';

  @override
  String get loginHeadline => 'Bem-vindo de volta';

  @override
  String get loginSubtitle =>
      'Entre com seu e-mail e senha para acessar sua carteira.';

  @override
  String get loginSubmitButton => 'Entrar';

  @override
  String get forgotPasswordLink => 'Esqueci minha senha';

  @override
  String get createAccountButton => 'Criar conta';

  @override
  String get loginCreateAccountSemanticLabel =>
      'Ainda não tem conta? Criar conta';

  @override
  String get corporateSsoButton => 'Entrar com SSO corporativo';

  @override
  String get signUpHeadline => 'Crie sua conta';

  @override
  String get signUpSubtitle =>
      'Comece a organizar sua carteira e seus pedidos em minutos.';

  @override
  String get fullNameFieldLabel => 'Nome completo';

  @override
  String get fullNameFieldSemanticLabel => 'Campo de nome';

  @override
  String get inviteEmailLockedHelperText =>
      'Este convite é exclusivo para este e-mail.';

  @override
  String get passwordHelperText =>
      'Mínimo de 8 caracteres, com letras e números.';

  @override
  String get confirmPasswordFieldLabel => 'Confirmar senha';

  @override
  String get confirmPasswordFieldSemanticLabel =>
      'Campo de confirmação de senha';

  @override
  String get termsAcceptanceRichPrefix => 'Li e aceito os ';

  @override
  String get termsOfServiceLinkText =>
      'Termos de Uso e a Política de Privacidade';

  @override
  String get termsAcceptanceLabel =>
      'Li e aceito os Termos de Uso e a Política de Privacidade.';

  @override
  String get termsAcceptanceSemanticLabel =>
      'Aceito os Termos de Uso e a Política de Privacidade';

  @override
  String get alreadyHaveAccountLink => 'Já tem conta? Entrar';

  @override
  String get forgotPasswordHeadline => 'Recuperar senha';

  @override
  String get forgotPasswordSubtitle =>
      'Informe seu e-mail e enviaremos as instruções para redefinir sua senha.';

  @override
  String get sendInstructionsButton => 'Enviar instruções';

  @override
  String get backToLoginLink => 'Voltar para o login';

  @override
  String get passwordResetGenericMessage =>
      'Se o e-mail informado existir em nossa base, você receberá instruções para redefinir sua senha.';

  @override
  String get languageSettingsTooltip => 'Idioma';

  @override
  String get languageSettingsTitle => 'Idioma';

  @override
  String get languageSettingsDescription =>
      'Escolha o idioma da interface do VestiPro neste dispositivo. Nomes de produtos, clientes e outros dados nunca são traduzidos — apenas os textos do aplicativo.';

  @override
  String languageSettingsAvailableCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count idiomas disponíveis',
      one: '$count idioma disponível',
    );
    return '$_temp0';
  }

  @override
  String get languageChangedConfirmation => 'Idioma alterado.';

  @override
  String get currentLanguageSemanticLabel => 'Idioma atual';
}
