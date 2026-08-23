import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../bloc/sign_up_bloc.dart';
import '../bloc/sign_up_event.dart';
import '../bloc/sign_up_state.dart';

/// The name/e-mail/password/confirmation fields, the Terms of Service
/// acceptance checkbox and the submit button (TASK-035).
///
/// Owns the [TextEditingController]s locally — same rationale as
/// `LoginForm` (TASK-034): [SignUpState]'s field values only ever change
/// *because* the user typed here, so an error/failure state never has a
/// reason to touch (let alone clear) what the user typed.
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmationController =
      TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordConfirmationFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmationFocusNode.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<SignUpBloc>().add(const SignUpEvent.submitted());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpBloc, SignUpState>(
      builder: (context, state) {
        final isSubmitting = state.status == SignUpSubmissionStatus.submitting;
        final canSubmit = state.termsAccepted && !isSubmitting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _nameController,
              label: 'Nome completo',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.nameError,
              textInputAction: TextInputAction.next,
              autofocus: true,
              semanticLabel: 'Campo de nome',
              prefixIcon: const Icon(Icons.person_outline),
              onChanged: (value) => context.read<SignUpBloc>().add(
                SignUpEvent.nameChanged(value),
              ),
              onSubmitted: (_) => _emailFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              label: 'E-mail',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              semanticLabel: 'Campo de e-mail',
              prefixIcon: const Icon(Icons.mail_outline),
              onChanged: (value) => context.read<SignUpBloc>().add(
                SignUpEvent.emailChanged(value),
              ),
              onSubmitted: (_) => _passwordFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppTextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              label: 'Senha',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.passwordError,
              obscureText: state.obscurePassword,
              textInputAction: TextInputAction.next,
              semanticLabel: 'Campo de senha',
              helperText: 'Mínimo de 8 caracteres, com letras e números.',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  state.obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: state.obscurePassword
                    ? 'Mostrar senha'
                    : 'Ocultar senha',
                onPressed: isSubmitting
                    ? null
                    : () => context.read<SignUpBloc>().add(
                        const SignUpEvent.passwordVisibilityToggled(),
                      ),
              ),
              onChanged: (value) => context.read<SignUpBloc>().add(
                SignUpEvent.passwordChanged(value),
              ),
              onSubmitted: (_) => _passwordConfirmationFocusNode.requestFocus(),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppTextField(
              controller: _passwordConfirmationController,
              focusNode: _passwordConfirmationFocusNode,
              label: 'Confirmar senha',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.passwordConfirmationError,
              obscureText: state.obscurePasswordConfirmation,
              textInputAction: TextInputAction.done,
              semanticLabel: 'Campo de confirmação de senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  state.obscurePasswordConfirmation
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                tooltip: state.obscurePasswordConfirmation
                    ? 'Mostrar senha'
                    : 'Ocultar senha',
                onPressed: isSubmitting
                    ? null
                    : () => context.read<SignUpBloc>().add(
                        const SignUpEvent.passwordConfirmationVisibilityToggled(),
                      ),
              ),
              onChanged: (value) => context.read<SignUpBloc>().add(
                SignUpEvent.passwordConfirmationChanged(value),
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppCheckbox(
              value: state.termsAccepted,
              isDisabled: isSubmitting,
              errorText: state.termsError,
              label:
                  'Li e aceito os Termos de Uso e a Política de Privacidade.',
              semanticLabel:
                  'Aceito os Termos de Uso e a Política de Privacidade',
              labelWidget: _TermsAcceptanceLabel(isDisabled: isSubmitting),
              onChanged: isSubmitting
                  ? null
                  : (_) => context.read<SignUpBloc>().add(
                      const SignUpEvent.termsAcceptanceToggled(),
                    ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppButton(
              label: 'Criar conta',
              expand: true,
              isLoading: isSubmitting,
              onPressed: canSubmit ? () => _submit(context) : null,
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Align(
              alignment: Alignment.center,
              child: AppButton(
                label: 'Já tem conta? Entrar',
                variant: AppButtonVariant.text,
                onPressed: isSubmitting
                    ? null
                    : () => context.go(const LoginRoute().location),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The terms-acceptance label text with a tappable link to
/// [TermsOfServiceRoute] — the actual terms content is TASK-156's
/// responsibility (EPIC-20); this form only consumes the link and registers
/// the acceptance (see `SignUpState.termsAccepted`).
class _TermsAcceptanceLabel extends StatelessWidget {
  const _TermsAcceptanceLabel({required this.isDisabled});

  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final baseStyle = AppTypography.bodyMedium.copyWith(
      color: isDisabled ? colors.disabled : colors.onSurface,
    );
    final linkStyle = baseStyle.copyWith(
      color: isDisabled ? colors.disabled : colors.primary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: <InlineSpan>[
          const TextSpan(text: 'Li e aceito os '),
          TextSpan(
            text: 'Termos de Uso e a Política de Privacidade',
            style: linkStyle,
            recognizer: isDisabled
                ? null
                : (TapGestureRecognizer()
                    ..onTap = () =>
                        context.push(const TermsOfServiceRoute().location)),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }
}
