import '../../../insights/domain/entities/insight.dart';

final class RepresentativeCustomerHighlight {
  const RepresentativeCustomerHighlight({
    required this.customerId,
    required this.customerName,
    this.insight,
  });

  final String customerId;
  final String customerName;
  final Insight? insight;
}
