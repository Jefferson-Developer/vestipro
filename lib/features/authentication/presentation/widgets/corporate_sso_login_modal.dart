import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/design_system.dart';
import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';

/// The "Entrar com SSO corporativo" flow (TASK-173): a minimal modal asking
/// only for the user's corporate e-mail, which [LoginBloc] resolves to an
/// organization's registered IdP (`resolveSsoForEmail`), authenticates
/// against (`AuthRepository.signInWithFederatedProvider`) and completes the
/// just-in-time provisioning decision for (`completeSsoLogin`) —
/// `SignInWithCorporateSsoUseCase` owns that whole sequence; this widget only
/// ever dispatches [LoginEvent.corporateSsoEmailChanged]/
/// [LoginEvent.corporateSsoSubmitted] and reacts to [LoginState].
///
/// Deliberately reuses [LoginBloc] instead of a bloc of its own: a
/// successful/failed corporate SSO login must drive `LoginPage`'s existing
/// `BlocListener` (status/failure/organizationId) exactly like the e-mail/
/// senha flow already does, so both ever reach the same post-login
/// destination through the same, single navigation decision.
abstract final class CorporateSsoLoginModal {
  const CorporateSsoLoginModal._();

  static Future<void> show(BuildContext context) {
    final loginBloc = context.read<LoginBloc>();
    return AppModal.show<void>(
      context: context,
      title: 'Entrar com SSO corporativo',
      showCloseButton: false,
      body: BlocProvider<LoginBloc>.value(
        value: loginBloc,
        child: const _CorporateSsoLoginModalBody(),
      ),
    );
  }
}

class _CorporateSsoLoginModalBody extends StatefulWidget {
  const _CorporateSsoLoginModalBody();

  @override
  State<_CorporateSsoLoginModalBody> createState() =>
      _CorporateSsoLoginModalBodyState();
}

class _CorporateSsoLoginModalBodyState
    extends State<_CorporateSsoLoginModalBody> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    context.read<LoginBloc>().add(const LoginEvent.corporateSsoSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return BlocConsumer<LoginBloc, LoginState>(
      // Closes the modal itself as soon as the corporate SSO submission
      // settles either way — success is then handled by `LoginPage`'s own
      // `BlocListener` (navigation), failure by its own `AppSnackbar`; this
      // modal never needs to render either outcome itself, only stop
      // blocking the login screen behind it once submitting is done.
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status != LoginSubmissionStatus.submitting,
      listener: (context, state) {
        if (state.status == LoginSubmissionStatus.success ||
            state.status == LoginSubmissionStatus.failure) {
          unawaited(Navigator.of(context).maybePop());
        }
      },
      builder: (context, state) {
        final isSubmitting = state.status == LoginSubmissionStatus.submitting;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Informe seu e-mail corporativo para entrar com o provedor de '
              'identidade (SSO) configurado pela sua organização.',
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            AppTextField(
              controller: _emailController,
              label: 'E-mail corporativo',
              isRequired: true,
              isDisabled: isSubmitting,
              errorText: state.corporateSsoEmailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofocus: true,
              semanticLabel: 'Campo de e-mail corporativo',
              prefixIcon: const Icon(Icons.badge_outlined),
              onChanged: (value) => context.read<LoginBloc>().add(
                LoginEvent.corporateSsoEmailChanged(value),
              ),
              onSubmitted: (_) => _submit(context),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.spacing12,
              runSpacing: AppSpacing.spacing12,
              children: <Widget>[
                AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.secondary,
                  isDisabled: isSubmitting,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                AppButton(
                  label: 'Entrar',
                  isLoading: isSubmitting,
                  onPressed: isSubmitting ? null : () => _submit(context),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
