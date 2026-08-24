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
