import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/whatsapp_models.dart';
import '../repositories/whatsapp_repository.dart';

@injectable
final class LoadWhatsAppContextUseCase {
  const LoadWhatsAppContextUseCase(this._repository);
  final WhatsAppRepository _repository;
  Future<AppResult<WhatsAppContext>> call({
    required String organizationId,
    required String customerId,
  }) => _repository.loadContext(
    organizationId: organizationId,
    customerId: customerId,
  );
}

@injectable
final class UpdateWhatsAppOptInUseCase {
  const UpdateWhatsAppOptInUseCase(this._repository);
  final WhatsAppRepository _repository;
  Future<AppResult<void>> call({
    required String organizationId,
    required String customerId,
    required WhatsAppOptInStatus status,
    required String channel,
  }) => _repository.updateOptIn(
    organizationId: organizationId,
    customerId: customerId,
    status: status,
    channel: channel,
  );
}

@injectable
final class SendWhatsAppMessageUseCase {
  const SendWhatsAppMessageUseCase(this._repository);
  final WhatsAppRepository _repository;
  Future<AppResult<WhatsAppSendResult>> call({
    required String organizationId,
    required String customerId,
    required String templateId,
    required List<String> variables,
    String? catalogShareId,
    String? notificationId,
  }) => _repository.send(
    organizationId: organizationId,
    customerId: customerId,
    templateId: templateId,
    variables: variables,
    catalogShareId: catalogShareId,
    notificationId: notificationId,
  );
}
