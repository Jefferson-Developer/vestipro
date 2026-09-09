import '../../../../core/errors/errors.dart';
import '../../domain/entities/quote.dart';
import 'quote_dto.dart';

final class QuoteConversionResultDto {
  const QuoteConversionResultDto({
    required this.quote,
    this.orderId,
    this.orderNumber,
    this.totalChanged = false,
    this.availabilityChanged = false,
    this.currentTotal,
    this.message,
  });

  factory QuoteConversionResultDto.fromJson(Map<String, dynamic> json) {
    final quoteJson = json['quote'];
    if (quoteJson is! Map<String, dynamic>) {
      throw const ServerException(
        'Unexpected quote conversion response shape.',
        code: 'invalid_quote_conversion_response',
      );
    }
    return QuoteConversionResultDto(
      quote: QuoteDto.fromJson(quoteJson),
      orderId: json['orderId'] as String?,
      orderNumber: json['orderNumber'] as String?,
      totalChanged: json['totalChanged'] == true,
      availabilityChanged: json['availabilityChanged'] == true,
      currentTotal: (json['currentTotal'] as num?)?.toDouble(),
      message: json['message'] as String?,
    );
  }

  final QuoteDto quote;
  final String? orderId;
  final String? orderNumber;
  final bool totalChanged;
  final bool availabilityChanged;
  final double? currentTotal;
  final String? message;

  QuoteConversionResult toEntity() {
    return QuoteConversionResult(
      quote: quote.toEntity(),
      orderId: orderId,
      orderNumber: orderNumber,
      totalChanged: totalChanged,
      availabilityChanged: availabilityChanged,
      currentTotal: currentTotal,
      message: message,
    );
  }
}
