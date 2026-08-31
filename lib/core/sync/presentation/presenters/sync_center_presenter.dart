import '../../../offline/domain/entities/offline_package_entity_kind.dart';
import '../../domain/entities/outbox_entity_type.dart';
import '../../domain/entities/outbox_operation.dart';

/// Business-friendly labels for the Central de Sincronização (TASK-112,
/// EPIC-14) — mirrors `conflict_presenter.dart`'s own restriction: "rótulos
/// de negócio, nunca nomes/erros técnicos".

/// A short, business-facing name for [kind] — the entities the offline
/// package (TASK-107) can carry to the device, shown next to their "última
/// sincronização completa" marker.
String offlinePackageEntityKindLabel(OfflinePackageEntityKind kind) {
  return switch (kind) {
    OfflinePackageEntityKind.customers => 'Clientes',
    OfflinePackageEntityKind.priceLists => 'Tabelas de preço',
    OfflinePackageEntityKind.paymentTerms => 'Condições de pagamento',
    OfflinePackageEntityKind.priceListItems => 'Itens de tabela de preço',
    OfflinePackageEntityKind.productVariants => 'Variantes de produto',
    OfflinePackageEntityKind.stockBalances => 'Saldo de estoque',
    OfflinePackageEntityKind.campaigns => 'Campanhas',
    OfflinePackageEntityKind.targets => 'Metas',
  };
}

/// A friendly, business-facing message for a failed [operation] — always a
/// fixed sentence per entity type, never [OutboxOperation.lastError]
/// (persisted verbatim from whatever a `SyncPushHandler`/backend rejection
/// raised, including a raw `exception.toString()` in `SyncEngine.runPush`'s
/// own catch-all path — never safe to show a user as-is). Mirrors TASK-112's
/// own example: "Não foi possível confirmar este pedido, verifique sua
/// conexão e tente novamente."
String syncFailureMessageLabel(OutboxOperation operation) {
  final entity = _entityTypeLabelLowercase(operation);
  return 'Não foi possível confirmar $entity. Verifique sua conexão e '
      'tente novamente.';
}

String _entityTypeLabelLowercase(OutboxOperation operation) {
  return switch (operation.entityType) {
    OutboxEntityType.order => 'este pedido',
    OutboxEntityType.orderItem => 'este item do pedido',
    OutboxEntityType.customer => 'este cliente',
    OutboxEntityType.crmActivity => 'esta atividade de CRM',
  };
}

/// `dd/MM/yyyy HH:mm`, local time — the same rendering
/// `conflictDetectedAtLabel` already uses across the sync feature, kept as
/// its own top-level function here so this presenter never has to import
/// `conflict_presenter.dart` just for date formatting.
String syncDateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
