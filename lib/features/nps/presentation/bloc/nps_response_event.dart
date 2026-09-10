sealed class NpsResponseEvent {
  const NpsResponseEvent();
}

/// Starts (or restarts, e.g. a manual "tentar novamente" after a network
/// error) loading the public preview for [token] — the URL's own path
/// parameter, resolved by `NpsResponseRoute`.
final class NpsResponseStarted extends NpsResponseEvent {
  const NpsResponseStarted({required this.token});

  final String token;
}

/// The customer picked a 0-10 score on the form.
final class NpsResponseScoreChanged extends NpsResponseEvent {
  const NpsResponseScoreChanged({required this.score});

  final int score;
}

/// The customer edited the optional comment field.
final class NpsResponseCommentChanged extends NpsResponseEvent {
  const NpsResponseCommentChanged({required this.comment});

  final String comment;
}

/// The customer tapped "Enviar" — submits the current [NpsResponseState]'s
/// own `score`/`comment` for `token`.
final class NpsResponseFormSubmitted extends NpsResponseEvent {
  const NpsResponseFormSubmitted();
}
