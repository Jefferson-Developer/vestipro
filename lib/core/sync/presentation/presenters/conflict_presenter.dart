import '../../domain/entities/conflict_policy.dart';
import '../../domain/entities/conflict_record.dart';
import '../../domain/entities/outbox_entity_type.dart';

/// Business-friendly labels for [ConflictRecord]/`OutboxEntityType` — TASK-111's
/// own restriction: "rótulos de negócio, nunca nomes técnicos de campo".
///
/// [conflictFieldLabel] falls back to a humanized version of the raw field
/// key for any field not explicitly mapped below — every VestiPro entity
/// snapshot key is already a `camelCase` Dart field name (never a raw
/// database/DTO key), so the fallback alone already reads reasonably in
/// Portuguese for an unmapped field; the explicit map only overrides the
/// handful of fields that read better with a dedicated label.

/// A short, business-facing name for [entityType] — never the raw
/// `OutboxEntityType.code`.
String conflictEntityTypeLabel(OutboxEntityType entityType) {
  return switch (entityType) {
    OutboxEntityType.order => 'Pedido',
    OutboxEntityType.orderItem => 'Item do pedido',
    OutboxEntityType.customer => 'Cliente',
    OutboxEntityType.crmActivity => 'Atividade de CRM',
  };
}

/// Whether [record] carries a financial/critical implication
/// (`ConflictPolicy.manualResolution` — orders and order items, the only
/// entities that policy is ever assigned to) — used to prioritize the list
/// and to badge the detail screen ("Crítico"), never to change what actions
/// are shown (every open conflict always offers "manter local"/"usar
/// remota"; only the field-by-field merge action is gated on [record.policy]
/// separately).
bool isCriticalConflict(ConflictRecord record) =>
    record.policy == ConflictPolicy.manualResolution;

/// Whether [record]'s policy allows a supervised field-by-field merge
/// (`ConflictPolicy.fieldMerge`) — the only case TASK-111's "Mesclar campo a
/// campo" action is offered for; a [ConflictPolicy.manualResolution] record
/// (orders/order items) only ever offers "manter local"/"usar remota".
bool allowsFieldMerge(ConflictRecord record) =>
    record.policy == ConflictPolicy.fieldMerge;

const Map<String, String> _knownFieldLabels = <String, String>{
  'name': 'Nome',
  'displayName': 'Nome',
  'email': 'E-mail',
  'phone': 'Telefone',
  'status': 'Status',
  'notes': 'Observações',
  'updatedAt': 'Última atualização',
  'version': 'Versão',
  'totalAmount': 'Valor total',
  'discountAmount': 'Desconto',
  'surchargeAmount': 'Acréscimo',
  'shippingAmount': 'Frete',
  'paymentTermId': 'Condição de pagamento',
  'quantity': 'Quantidade',
  'unitPrice': 'Preço unitário',
  'addressLine1': 'Endereço',
  'addressLine2': 'Complemento',
  'city': 'Cidade',
  'state': 'Estado',
  'zipCode': 'CEP',
};

/// The business label for one divergent field [key], e.g. `totalAmount` ->
/// "Valor total" — never the raw technical key.
String conflictFieldLabel(String key) =>
    _knownFieldLabels[key] ?? _humanize(key);

String _humanize(String key) {
  final withSpaces = key
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ');
  if (withSpaces.isEmpty) return key;
  return '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
}

/// A human-readable rendering of one field's raw [value] — never a raw
/// `null`/`Map`/technical `toString()`.
String conflictFieldValueLabel(Object? value) {
  return switch (value) {
    null => 'Vazio',
    DateTime date => _dateTimeLabel(date),
    bool flag => flag ? 'Sim' : 'Não',
    Iterable<Object?> values => values.map(conflictFieldValueLabel).join(', '),
    Map<Object?, Object?> _ => 'Dados estruturados',
    _ => value.toString(),
  };
}

/// `dd/MM/yyyy HH:mm`, local time — the same rendering
/// `auditDetailsLabel`/`_dateTimeLabel` already use across the app.
String conflictDetectedAtLabel(DateTime detectedAt) =>
    _dateTimeLabel(detectedAt);

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
