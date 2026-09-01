import '../../domain/entities/audit_log_entry.dart';
import '../../domain/value_objects/audit_action.dart';

String auditActionLabel(AuditAction action) {
  return switch (action) {
    AuditAction.userLogin => 'Login',
    AuditAction.organizationCreated => 'Organização criada',
    AuditAction.roleChanged || AuditAction.userRoleUpdated => 'Role alterada',
    AuditAction.userInvited => 'Convite criado',
    AuditAction.userInviteResent => 'Convite reenviado',
    AuditAction.userInviteRevoked => 'Convite revogado',
    AuditAction.userInviteAccepted => 'Convite aceito',
    AuditAction.userDeactivated => 'Usuário desativado',
    AuditAction.userReactivated => 'Usuário reativado',
    AuditAction.userDeleted => 'Usuário excluído',
    AuditAction.companyDeleted => 'Empresa excluída',
    AuditAction.branchDeleted => 'Filial excluída',
    AuditAction.teamDeleted => 'Equipe excluída',
    AuditAction.roleDeleted => 'Role excluída',
    AuditAction.organizationSettingsUpdated => 'Configuração alterada',
    AuditAction.productPublished => 'Produto publicado',
    AuditAction.productUpdated => 'Produto alterado',
    AuditAction.inventoryBalanceAdjusted => 'Saldo de estoque ajustado',
    AuditAction.paymentTermCreated => 'Condição criada',
    AuditAction.paymentTermUpdated => 'Condição alterada',
    AuditAction.paymentTermDeactivated => 'Condição inativada',
    AuditAction.discountPolicyCreated => 'Política de desconto criada',
    AuditAction.discountPolicyUpdated => 'Política de desconto alterada',
    AuditAction.discountPolicyDeactivated => 'Política de desconto inativada',
    AuditAction.promotionalCampaignCreated => 'Campanha promocional criada',
    AuditAction.promotionalCampaignUpdated => 'Campanha promocional alterada',
    AuditAction.promotionalCampaignEnded => 'Campanha promocional encerrada',
    AuditAction.targetUpdated => 'Meta alterada',
  };
}

String auditEntityLabel(AuditLogEntry entry) {
  final type = switch (entry.entityType) {
    'organization' => 'Organização',
    'membership' => 'Usuário',
    'invite' => 'Convite',
    'company' => 'Empresa',
    'branch' => 'Filial',
    'team' => 'Equipe',
    'role' => 'Role',
    'settings' => 'Configuração',
    'product' => 'Produto',
    'inventoryBalance' => 'Saldo de estoque',
    'paymentTerm' => 'Condição',
    'discountPolicy' => 'Política de desconto',
    'promotionalCampaign' => 'Campanha promocional',
    'target' => 'Meta',
    _ => entry.entityType,
  };
  return '$type ${entry.entityId}';
}

String auditDetailsLabel(AuditLogEntry entry) {
  final previousValue = entry.previousValue ?? const <String, Object?>{};
  final newValue = entry.newValue ?? const <String, Object?>{};
  final keys = <String>{...previousValue.keys, ...newValue.keys}.toList()
    ..sort();

  if (keys.isEmpty) {
    return 'Registro sem detalhes adicionais';
  }

  final lines = <String>[];
  for (final key in keys) {
    final previous = previousValue[key];
    final next = newValue[key];
    if (_valuesMatch(previous, next)) continue;

    final field = _fieldLabel(key);
    if (previous == null && next != null) {
      lines.add('$field: ${_valueLabel(next)}');
    } else if (previous != null && next == null) {
      lines.add('$field removido');
    } else {
      lines.add('$field: ${_valueLabel(previous)} -> ${_valueLabel(next)}');
    }
  }

  return lines.isEmpty ? 'Sem alteração de valores' : lines.join('\n');
}

bool _valuesMatch(Object? previous, Object? next) {
  if (previous == next) return true;
  return previous?.toString() == next?.toString();
}

String _fieldLabel(String key) {
  return switch (key) {
    'roleId' || 'roleName' => 'Perfil',
    'status' => 'Status',
    'email' => 'E-mail',
    'name' => 'Nome',
    'targetUserId' || 'userId' => 'Usuário',
    'teamIds' => 'Equipes',
    'managerUserId' => 'Gestor',
    'message' => 'Mensagem',
    _ => _humanizeKey(key),
  };
}

String _humanizeKey(String key) {
  final withSpaces = key
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .replaceAll('_', ' ');
  if (withSpaces.isEmpty) return key;
  return '${withSpaces[0].toUpperCase()}${withSpaces.substring(1)}';
}

String _valueLabel(Object? value) {
  return switch (value) {
    null => '-',
    DateTime date => _dateTimeLabel(date),
    Iterable<Object?> values => values.map(_valueLabel).join(', '),
    Map<Object?, Object?> _ => 'dados estruturados',
    bool flag => flag ? 'Sim' : 'Não',
    _ => value.toString(),
  };
}

String _dateTimeLabel(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
