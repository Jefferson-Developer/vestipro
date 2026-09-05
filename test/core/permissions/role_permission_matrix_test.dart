import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('RolePermissionMatrix', () {
    test('OWNER has every capability', () {
      final ownerCapabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.owner,
      );

      expect(ownerCapabilities, Capability.values.toSet());
    });

    test('OWNER is always a strict superset of ADMIN', () {
      final ownerCapabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.owner,
      );
      final adminCapabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.admin,
      );

      expect(ownerCapabilities.containsAll(adminCapabilities), isTrue);
      expect(
        ownerCapabilities.length,
        greaterThan(adminCapabilities.length),
        reason: 'OWNER must have at least one capability ADMIN does not.',
      );
    });

    test('ADMIN has every capability except organizationTransferOwnership', () {
      final adminCapabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.admin,
      );

      expect(
        adminCapabilities.contains(Capability.organizationTransferOwnership),
        isFalse,
      );
      expect(adminCapabilities.contains(Capability.userChangeRole), isTrue);
      expect(adminCapabilities.contains(Capability.roleManage), isTrue);
      expect(adminCapabilities.contains(Capability.customerDelete), isTrue);
    });

    test('SALES_MANAGER can create/delete customers and approve orders and '
        'discounts, but cannot manage roles nor transfer ownership', () {
      final capabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.salesManager,
      );

      expect(capabilities.contains(Capability.customerCreate), isTrue);
      expect(capabilities.contains(Capability.customerDelete), isTrue);
      expect(capabilities.contains(Capability.orderApprove), isTrue);
      expect(
        capabilities.contains(Capability.discountApproveAboveLimit),
        isTrue,
      );
      expect(capabilities.contains(Capability.roleManage), isFalse);
      expect(capabilities.contains(Capability.userChangeRole), isFalse);
      expect(
        capabilities.contains(Capability.organizationTransferOwnership),
        isFalse,
      );
    });

    test('SALES_REP can create customers and orders but cannot delete '
        'customers nor approve orders/discounts', () {
      final capabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.salesRep,
      );

      expect(capabilities.contains(Capability.customerCreate), isTrue);
      expect(capabilities.contains(Capability.orderCreate), isTrue);
      expect(capabilities.contains(Capability.customerDelete), isFalse);
      expect(capabilities.contains(Capability.orderApprove), isFalse);
      expect(
        capabilities.contains(Capability.discountApproveAboveLimit),
        isFalse,
      );
    });

    test('SALES_REP and SALES_MANAGER can view orders (TASK-102), but '
        'SALES_ASSISTANT/FINANCE/READ_ONLY cannot', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.salesRep,
        SystemRoleName.salesManager,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.orderView),
          isTrue,
          reason: '$role must see the pedidos listing.',
        );
      }

      for (final role in <SystemRoleName>[
        SystemRoleName.salesAssistant,
        SystemRoleName.finance,
        SystemRoleName.readOnly,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.orderView),
          isFalse,
          reason: '$role must never see the pedidos listing.',
        );
      }
    });

    test(
      'SALES_ASSISTANT can only create/update customers and create leads',
      () {
        final capabilities = RolePermissionMatrix.capabilitiesFor(
          SystemRoleName.salesAssistant,
        );

        expect(capabilities, <Capability>{
          Capability.customerCreate,
          Capability.customerUpdate,
          Capability.leadCreate,
        });
      },
    );

    test('SALES_REP and SALES_MANAGER can view/create/qualify leads, but '
        'SALES_ASSISTANT/FINANCE/READ_ONLY cannot qualify them (TASK-056)', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.salesRep,
        SystemRoleName.salesManager,
      ]) {
        final capabilities = RolePermissionMatrix.capabilitiesFor(role);
        expect(
          capabilities.contains(Capability.leadView),
          isTrue,
          reason: '$role must see the lead list.',
        );
        expect(
          capabilities.contains(Capability.leadCreate),
          isTrue,
          reason: '$role must be able to register a lead.',
        );
        expect(
          capabilities.contains(Capability.leadQualify),
          isTrue,
          reason: '$role must be able to qualify/disqualify a lead.',
        );
      }

      for (final role in <SystemRoleName>[
        SystemRoleName.salesAssistant,
        SystemRoleName.finance,
        SystemRoleName.readOnly,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.leadQualify),
          isFalse,
          reason: '$role must never qualify/disqualify a lead.',
        );
      }
    });

    test('FINANCE can view/manage finance, approve discounts above limit and '
        'see the lead pipeline for forecasting, but cannot manage customers/'
        'orders nor qualify a lead', () {
      final capabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.finance,
      );

      expect(capabilities.contains(Capability.financeView), isTrue);
      expect(capabilities.contains(Capability.financeManage), isTrue);
      expect(
        capabilities.contains(Capability.discountApproveAboveLimit),
        isTrue,
      );
      expect(capabilities.contains(Capability.leadView), isTrue);
      expect(capabilities.contains(Capability.leadQualify), isFalse);
      expect(capabilities.contains(Capability.customerCreate), isFalse);
      expect(capabilities.contains(Capability.orderApprove), isFalse);
    });

    test('only OWNER/ADMIN/FINANCE can manage Price Lists (TASK-083); '
        'SALES_MANAGER/SALES_REP/SALES_ASSISTANT/READ_ONLY never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.finance,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.priceListManage),
          isTrue,
          reason: '$role must be able to manage price lists.',
        );
      }

      for (final role in <SystemRoleName>[
        SystemRoleName.salesManager,
        SystemRoleName.salesRep,
        SystemRoleName.salesAssistant,
        SystemRoleName.readOnly,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.priceListManage),
          isFalse,
          reason: '$role must never manage price lists.',
        );
      }
    });

    test('only OWNER/ADMIN/SALES_MANAGER can manage targets (TASK-115); '
        'SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.targetManage),
          isTrue,
          reason: '$role must be able to manage targets.',
        );
      }

      for (final role in <SystemRoleName>[
        SystemRoleName.salesRep,
        SystemRoleName.salesAssistant,
        SystemRoleName.finance,
        SystemRoleName.readOnly,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.targetManage),
          isFalse,
          reason: '$role must never manage targets.',
        );
      }
    });

    test('OWNER/ADMIN/SALES_MANAGER/SALES_REP can view the achievement '
        'dashboard (TASK-116); SALES_ASSISTANT/FINANCE/READ_ONLY cannot', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
        SystemRoleName.salesRep,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.targetView),
          isTrue,
          reason: '$role must be able to view the achievement dashboard.',
        );
      }

      for (final role in <SystemRoleName>[
        SystemRoleName.salesAssistant,
        SystemRoleName.finance,
        SystemRoleName.readOnly,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.targetView),
          isFalse,
          reason: '$role must never view the achievement dashboard.',
        );
      }
    });

    test(
      'OWNER/ADMIN/SALES_MANAGER/SALES_REP can view the Central de '
      'Oportunidades (TASK-132); SALES_ASSISTANT/FINANCE/READ_ONLY cannot',
      () {
        for (final role in <SystemRoleName>[
          SystemRoleName.owner,
          SystemRoleName.admin,
          SystemRoleName.salesManager,
          SystemRoleName.salesRep,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.insightView),
            isTrue,
            reason: '$role must be able to view the Central de Oportunidades.',
          );
        }

        for (final role in <SystemRoleName>[
          SystemRoleName.salesAssistant,
          SystemRoleName.finance,
          SystemRoleName.readOnly,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.insightView),
            isFalse,
            reason: '$role must never view the Central de Oportunidades.',
          );
        }
      },
    );

    test('OWNER/ADMIN/SALES_MANAGER/FINANCE can share a saved report with '
        'the whole organization (TASK-145); SALES_REP caps out at team-level '
        'sharing; SALES_ASSISTANT/READ_ONLY cannot share at all', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
        SystemRoleName.finance,
      ]) {
        final capabilities = RolePermissionMatrix.capabilitiesFor(role);
        expect(
          capabilities.contains(Capability.reportShareTeam),
          isTrue,
          reason: '$role must be able to share a saved report with a team.',
        );
        expect(
          capabilities.contains(Capability.reportShareOrganization),
          isTrue,
          reason: '$role must be able to share a saved report org-wide.',
        );
      }

      final salesRepCapabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.salesRep,
      );
      expect(
        salesRepCapabilities.contains(Capability.reportShareTeam),
        isTrue,
        reason:
            'SALES_REP must be able to share a saved report with a '
            'team.',
      );
      expect(
        salesRepCapabilities.contains(Capability.reportShareOrganization),
        isFalse,
        reason: 'SALES_REP must never share a saved report org-wide.',
      );

      for (final role in <SystemRoleName>[
        SystemRoleName.salesAssistant,
        SystemRoleName.readOnly,
      ]) {
        final capabilities = RolePermissionMatrix.capabilitiesFor(role);
        expect(
          capabilities.contains(Capability.reportShareTeam),
          isFalse,
          reason: '$role must never share a saved report with a team.',
        );
        expect(
          capabilities.contains(Capability.reportShareOrganization),
          isFalse,
          reason: '$role must never share a saved report org-wide.',
        );
      }
    });

    test('READ_ONLY never has any capability', () {
      final capabilities = RolePermissionMatrix.capabilitiesFor(
        SystemRoleName.readOnly,
      );

      expect(capabilities, isEmpty);
    });

    test('READ_ONLY never has any write/delete/approve capability across the '
        'full matrix (invariant, not just this role by itself)', () {
      for (final capability in Capability.values) {
        expect(
          RolePermissionMatrix.hasCapability(
            SystemRoleName.readOnly,
            capability,
          ),
          isFalse,
          reason: 'READ_ONLY must never grant $capability.',
        );
      }
    });

    test('every system role is auditable: capabilitiesFor never throws and '
        'always returns a deterministic, exact set', () {
      for (final role in SystemRoleName.values) {
        final first = RolePermissionMatrix.capabilitiesFor(role);
        final second = RolePermissionMatrix.capabilitiesFor(role);
        expect(first, second);
      }
    });

    test('capabilitiesForRoleName resolves system roles from their raw '
        'Firestore code (e.g. "OWNER")', () {
      expect(
        RolePermissionMatrix.capabilitiesForRoleName('OWNER'),
        Capability.values.toSet(),
      );
      expect(
        RolePermissionMatrix.capabilitiesForRoleName('READ_ONLY'),
        isEmpty,
      );
    });

    test(
      'capabilitiesForRoleName default-denies unknown/custom role names',
      () {
        expect(
          RolePermissionMatrix.capabilitiesForRoleName('CUSTOM_ROLE'),
          isEmpty,
        );
      },
    );
  });
}
