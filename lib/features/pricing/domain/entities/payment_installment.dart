final class PaymentInstallment {
  const PaymentInstallment({required this.percentage, required this.dueInDays});

  final double percentage;
  final int dueInDays;

  Map<String, Object?> toJson() {
    return <String, Object?>{'percentage': percentage, 'dueInDays': dueInDays};
  }

  static PaymentInstallment fromJson(Map<String, Object?> json) {
    return PaymentInstallment(
      percentage: (json['percentage'] as num).toDouble(),
      dueInDays: (json['dueInDays'] as num).toInt(),
    );
  }
}
