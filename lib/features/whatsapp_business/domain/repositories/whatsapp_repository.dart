import '../../../../core/utils/utils.dart';
import '../entities/whatsapp_models.dart';

abstract interface class WhatsAppRepository {
  Future<AppResult<WhatsAppContext>> loadContext({
    required String organizationId,
    required String customerId,
  });

  Future<AppResult<void>> updateOptIn({
    required String organizationId,
    required String customerId,
    required WhatsAppOptInStatus status,
    required String channel,
  });

  Future<AppResult<WhatsAppSendResult>> send({
    required String organizationId,
    required String customerId,
    required String templateId,
    required List<String> variables,
    String? catalogShareId,
    String? notificationId,
  });
}
