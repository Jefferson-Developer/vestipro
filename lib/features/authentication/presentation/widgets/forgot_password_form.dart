import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/navigation/navigation.dart';
import '../bloc/forgot_password_bloc.dart';
import '../bloc/forgot_password_event.dart';
import '../bloc/forgot_password_state.dart';

/// The e-mail field, submit button and "Voltar para o login" link
/// (TASK-036).
///
/// Owns the [TextEditingController] locally — [ForgotPasswordState.email]
/// only ever changes *because* the user typed here, same rationale as
/// `LoginForm` (TASK-034). Stays on screen after a successful submission
/// (there is nothing to navigate to yet: the actual password redefinition
/// happens through the link Firebase sends by e-mail, outside the app), so
/// the user can immediately request another e-mail if the first one never
/// arrives, without losing what they typed.
class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<ForgotPasswordBloc>().add(
      const ForgotPasswordEvent.submitted(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForgotPasswordBloc, ForgotPasswordState>(
      builder: (context, state) {
        final isSubmitting =
            state.status == ForgotPasswordSubmissionStatus.submitting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTextField(
              controller: _emailController,
              label: 'E-mail',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: true,
              semanticLabel: 'Campo de e-mail',
              prefixIcon: const Icon(Icons.mail_outline),
              onChanged: (value) => context.read<ForgotPasswordBloc>().add(
                ForgotPasswordEvent.emailChanged(value),
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            AppButton(
              label: 'Enviar instruções',
              expand: true,
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : () => _submit(context),
            ),
            const SizedBox(height: AppSpacing.spacing8),
            Align(
              alignment: Alignment.center,
              child: AppButton(
                label: 'Voltar para o login',
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
