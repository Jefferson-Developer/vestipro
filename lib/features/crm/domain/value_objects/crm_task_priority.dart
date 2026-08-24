enum CrmTaskPriority {
  low,
  medium,
  high;

  String get label {
    return switch (this) {
      CrmTaskPriority.low => 'Baixa',
      CrmTaskPriority.medium => 'Media',
      CrmTaskPriority.high => 'Alta',
    };
  }
}
