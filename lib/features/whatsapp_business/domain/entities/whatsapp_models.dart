enum WhatsAppOptInStatus { requested, accepted, refused, revoked }

enum WhatsAppDeliveryStatus { sent, delivered, read, failed }

final class WhatsAppOptIn {
  const WhatsAppOptIn({
    required this.customerId,
    required this.status,
    required this.channel,
    required this.requestedAt,
    this.decidedAt,
    this.revokedAt,
  });

  final String customerId;
  final WhatsAppOptInStatus status;
  final String channel;
  final DateTime requestedAt;
  final DateTime? decidedAt;
  final DateTime? revokedAt;

  bool get isActive => status == WhatsAppOptInStatus.accepted;
}

final class WhatsAppTemplate {
  const WhatsAppTemplate({
    required this.id,
    required this.name,
    required this.language,
    required this.variables,
    this.description,
  });

  final String id;
  final String name;
  final String language;
  final List<String> variables;
  final String? description;
}

final class WhatsAppMessage {
  const WhatsAppMessage({
    required this.id,
    required this.templateName,
    required this.status,
    required this.createdAt,
    this.failureReason,
  });

  final String id;
  final String templateName;
  final WhatsAppDeliveryStatus status;
  final DateTime createdAt;
  final String? failureReason;
}

final class WhatsAppContext {
  const WhatsAppContext({
    required this.templates,
    required this.messages,
    this.optIn,
  });

  final WhatsAppOptIn? optIn;
  final List<WhatsAppTemplate> templates;
  final List<WhatsAppMessage> messages;
}

final class WhatsAppSendResult {
  const WhatsAppSendResult({required this.messageId, required this.status});
  final String messageId;
  final WhatsAppDeliveryStatus status;
}
