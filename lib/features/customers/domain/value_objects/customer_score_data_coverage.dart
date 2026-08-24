enum CustomerScoreDataCoverage {
  ordersAndCrm,
  crmOnly,
  registrationOnly;

  String get code {
    return switch (this) {
      CustomerScoreDataCoverage.ordersAndCrm => 'ordersAndCrm',
      CustomerScoreDataCoverage.crmOnly => 'crmOnly',
      CustomerScoreDataCoverage.registrationOnly => 'registrationOnly',
    };
  }

  String get label {
    return switch (this) {
      CustomerScoreDataCoverage.ordersAndCrm => 'Pedidos e CRM',
      CustomerScoreDataCoverage.crmOnly => 'CRM sem pedidos',
      CustomerScoreDataCoverage.registrationOnly => 'Cadastro sem historico',
    };
  }
}
