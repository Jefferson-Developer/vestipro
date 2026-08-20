import '../../../../core/errors/errors.dart';
import '../../domain/entities/about_app.dart';

sealed class AboutAppState {
  const AboutAppState();
}

final class AboutAppInitial extends AboutAppState {
  const AboutAppInitial();
}

final class AboutAppLoading extends AboutAppState {
  const AboutAppLoading();
}

final class AboutAppLoaded extends AboutAppState {
  const AboutAppLoaded(this.aboutApp);

  final AboutApp aboutApp;
}

final class AboutAppError extends AboutAppState {
  const AboutAppError(this.failure);

  final Failure failure;
}
