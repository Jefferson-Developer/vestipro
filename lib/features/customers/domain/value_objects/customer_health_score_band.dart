enum CustomerHealthScoreBand {
  healthy,
  attention,
  risk;

  String get code {
    return switch (this) {
      CustomerHealthScoreBand.healthy => 'healthy',
      CustomerHealthScoreBand.attention => 'attention',
      CustomerHealthScoreBand.risk => 'risk',
    };
  }

  String get label {
    return switch (this) {
      CustomerHealthScoreBand.healthy => 'Saudavel',
      CustomerHealthScoreBand.attention => 'Atencao',
      CustomerHealthScoreBand.risk => 'Risco',
    };
  }
}
