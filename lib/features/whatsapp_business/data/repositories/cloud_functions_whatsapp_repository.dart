import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/whatsapp_models.dart';
import '../../domain/repositories/whatsapp_repository.dart';

@LazySingleton(as: WhatsAppRepository)
final class CloudFunctionsWhatsAppRepository implements WhatsAppRepository {
  const CloudFunctionsWhatsAppRepository(this._functions);
  final CloudFunctionsService _functions;

  @override
  Future<AppResult<WhatsAppContext>> loadContext({
    required String organizationId,
    required String customerId,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'getWhatsAppContext',
      requireAuth: true,
      data: {'organizationId': organizationId, 'customerId': customerId},
    );
    final rawOptIn = json['optIn'];
    return WhatsAppContext(
      optIn: rawOptIn is Map
          ? _optIn(Map<String, dynamic>.from(rawOptIn))
          : null,
      templates: (json['templates'] as List<dynamic>? ?? const [])
          .map((item) => _template(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((item) => _message(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  });

  @override
  Future<AppResult<void>> updateOptIn({
    required String organizationId,
    required String customerId,
    required WhatsAppOptInStatus status,
    required String channel,
  }) => _guard(() async {
    await _functions.call<Map<String, dynamic>>(
      'updateWhatsAppOptIn',
      requireAuth: true,
      data: {
        'organizationId': organizationId,
        'customerId': customerId,
        'status': status.name,
        'channel': channel,
      },
    );
  });

  @override
  Future<AppResult<WhatsAppSendResult>> send({
    required String organizationId,
    required String customerId,
    required String templateId,
    required List<String> variables,
    String? catalogShareId,
    String? notificationId,
  }) => _guard(() async {
    final json = await _functions.call<Map<String, dynamic>>(
      'sendWhatsAppMessage',
      requireAuth: true,
      data: {
        'organizationId': organizationId,
        'customerId': customerId,
        'templateId': templateId,
        'variables': variables,
        'catalogShareId': ?catalogShareId,
        'notificationId': ?notificationId,
      },
    );
    return WhatsAppSendResult(
      messageId: json['messageId'] as String,
      status: _deliveryStatus(json['status'] as String),
    );
  });

  Future<AppResult<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return AppSuccess<T>(await action());
    } on AppException catch (error) {
      return AppFailure<T>(mapAppExceptionToFailure(error));
    } catch (error) {
      return AppFailure<T>(
        UnexpectedFailure(
          'Falha inesperada na comunicacao por WhatsApp.',
          cause: error,
        ),
      );
    }
  }

  WhatsAppOptIn _optIn(Map<String, dynamic> json) => WhatsAppOptIn(
    customerId: json['customerId'] as String,
    status: WhatsAppOptInStatus.values.byName(json['status'] as String),
    channel: json['channel'] as String,
    requestedAt: DateTime.parse(json['requestedAt'] as String),
    decidedAt: _date(json['decidedAt']),
    revokedAt: _date(json['revokedAt']),
  );

  WhatsAppTemplate _template(Map<String, dynamic> json) => WhatsAppTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    language: json['language'] as String,
    variables: (json['variables'] as List<dynamic>? ?? const []).cast<String>(),
    description: json['description'] as String?,
  );

  WhatsAppMessage _message(Map<String, dynamic> json) => WhatsAppMessage(
    id: json['id'] as String,
    templateName: (json['templateName'] as String?) ?? 'Template',
    status: _deliveryStatus(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    failureReason: json['failureReason'] as String?,
  );

  DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value) : null;
  WhatsAppDeliveryStatus _deliveryStatus(String value) =>
      WhatsAppDeliveryStatus.values.byName(value);
}
