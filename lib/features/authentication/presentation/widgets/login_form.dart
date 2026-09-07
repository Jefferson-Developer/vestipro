import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import 'corporate_sso_login_modal.dart';

/// The e-mail/password fields, submit button and "Esqueci minha senha" link
/// (TASK-034).
///
/// Owns the [TextEditingController]s locally — [LoginState.email]/[password]
/// only ever change *because* the user typed here, so the controllers never
/// need to be resynced from the bloc, which also means an error/failure
/// state never has a reason to touch (let alone clear) what the user typed.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<LoginBloc>().add(const LoginEvent.submitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isSubmitting = state.status == LoginSubmissionStatus.submitting;
        final l10n = AppLocalizations.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _emailController,
              label: l10n.emailFieldLabel,
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofocus: true,
              semanticLabel: l10n.emailFieldSemanticLabel,
              prefixIcon: const Icon(Icons.mail_outline),
              onChanged: (value) =>
                  context.read<LoginBloc>().add(LoginEvent.emailChanged(value)),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: l10n.passwordFieldLabel,
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.passwordError,
              obscureText: state.obscurePassword,
              textInputAction: TextInputAction.done,
              semanticLabel: l10n.passwordFieldSemanticLabel,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  state.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: state.obscurePassword
                    ? l10n.showPasswordTooltip
                    : l10n.hidePasswordTooltip,
                onPressed: isSubmitting
                    ? null
                    : () => context.read<LoginBloc>().add(
                        const LoginEvent.passwordVisibilityToggled(),
                      ),
              ),
              onChanged: (value) => context.read<LoginBloc>().add(
                LoginEvent.passwordChanged(value),
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                label: l10n.forgotPasswordLink,
                variant: AppButtonVariant.text,
                onPressed: isSubmitting
                    ? null
                    : () => context.go(const PasswordResetRoute().location),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            AppButton(
              label: l10n.loginSubmitButton,
              expand: true,
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : () => _submit(context),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Align(
              alignment: Alignment.center,
              child: AppButton(
                label: l10n.createAccountButton,
                semanticLabel: l10n.loginCreateAccountSemanticLabel,
                variant: AppButtonVariant.text,
                onPressed: isSubmitting
                    ? null
                    : () => context.go(const SignUpRoute().location),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Align(
              alignment: Alignment.center,
              child: AppButton(
                label: l10n.corporateSsoButton,
                semanticLabel: l10n.corporateSsoButton,
                variant: AppButtonVariant.text,
                onPressed: isSubmitting
                    ? null
                    : () => unawaited(CorporateSsoLoginModal.show(context)),
              ),
            ),
          ],
        );
      },
    );
  }
}
