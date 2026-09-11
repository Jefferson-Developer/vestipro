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

    test('only OWNER/ADMIN/SALES_MANAGER can schedule reports (TASK-149); '
        'SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.reportSchedule),
          isTrue,
          reason: '$role must be able to schedule reports.',
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
          ).contains(Capability.reportSchedule),
          isFalse,
          reason: '$role must never be able to schedule reports.',
        );
      }
    });

    test(
      'only OWNER/ADMIN can configure ERP integrations (TASK-169); '
      'SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can',
      () {
        for (final role in <SystemRoleName>[
          SystemRoleName.owner,
          SystemRoleName.admin,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.erpIntegrationManage),
            isTrue,
            reason: '$role must be able to configure ERP integrations.',
          );
        }

        for (final role in <SystemRoleName>[
          SystemRoleName.salesManager,
          SystemRoleName.salesRep,
          SystemRoleName.salesAssistant,
          SystemRoleName.finance,
          SystemRoleName.readOnly,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.erpIntegrationManage),
            isFalse,
            reason: '$role must never configure ERP integrations.',
          );
        }
      },
    );

    test(
      'only OWNER/ADMIN can configure outbound webhooks (TASK-170); '
      'SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can',
      () {
        for (final role in <SystemRoleName>[
          SystemRoleName.owner,
          SystemRoleName.admin,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.webhookManage),
            isTrue,
            reason: '$role must be able to configure webhooks.',
          );
        }

        for (final role in <SystemRoleName>[
          SystemRoleName.salesManager,
          SystemRoleName.salesRep,
          SystemRoleName.salesAssistant,
          SystemRoleName.finance,
          SystemRoleName.readOnly,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.webhookManage),
            isFalse,
            reason: '$role must never configure webhooks.',
          );
        }
      },
    );

    test(
      'only OWNER/ADMIN can manage public API keys (TASK-171); '
      'SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can',
      () {
        for (final role in <SystemRoleName>[
          SystemRoleName.owner,
          SystemRoleName.admin,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.apiKeyManage),
            isTrue,
            reason: '$role must be able to manage public API keys.',
          );
        }

        for (final role in <SystemRoleName>[
          SystemRoleName.salesManager,
          SystemRoleName.salesRep,
          SystemRoleName.salesAssistant,
          SystemRoleName.finance,
          SystemRoleName.readOnly,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.apiKeyManage),
            isFalse,
            reason: '$role must never manage public API keys.',
          );
        }
      },
    );

    test(
      'only OWNER/ADMIN can manage corporate SSO connections (TASK-173); '
      'SALES_MANAGER/SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can',
      () {
        for (final role in <SystemRoleName>[
          SystemRoleName.owner,
          SystemRoleName.admin,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.ssoManage),
            isTrue,
            reason: '$role must be able to configure corporate SSO.',
          );
        }

        for (final role in <SystemRoleName>[
          SystemRoleName.salesManager,
          SystemRoleName.salesRep,
          SystemRoleName.salesAssistant,
          SystemRoleName.finance,
          SystemRoleName.readOnly,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.ssoManage),
            isFalse,
            reason: '$role must never configure corporate SSO.',
          );
        }
      },
    );

    test('OWNER/ADMIN/SALES_MANAGER/SALES_REP can request a devolução '
        '(TASK-199); SALES_ASSISTANT/FINANCE/READ_ONLY never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
        SystemRoleName.salesRep,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.returnRequestCreate),
          isTrue,
          reason: '$role must be able to request a devolução.',
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
          ).contains(Capability.returnRequestCreate),
          isFalse,
          reason: '$role must never be able to request a devolução.',
        );
      }
    });

    test('only OWNER/ADMIN/SALES_MANAGER can decide (aprovar/recusar) a '
        'devolução (TASK-199); SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY '
        'never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.returnRequestApprove),
          isTrue,
          reason: '$role must be able to decide a devolução.',
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
          ).contains(Capability.returnRequestApprove),
          isFalse,
          reason: '$role must never decide a devolução.',
        );
      }
    });

    test('OWNER/ADMIN/SALES_MANAGER/SALES_REP can request a troca '
        '(TASK-200); SALES_ASSISTANT/FINANCE/READ_ONLY never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
        SystemRoleName.salesRep,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.exchangeRequestCreate),
          isTrue,
          reason: '$role must be able to request a troca.',
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
          ).contains(Capability.exchangeRequestCreate),
          isFalse,
          reason: '$role must never be able to request a troca.',
        );
      }
    });

    test('only OWNER/ADMIN/SALES_MANAGER can decide (aprovar/recusar) a '
        'troca (TASK-200); SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY '
        'never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.exchangeRequestApprove),
          isTrue,
          reason: '$role must be able to decide a troca.',
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
          ).contains(Capability.exchangeRequestApprove),
          isFalse,
          reason: '$role must never decide a troca.',
        );
      }
    });

    test('OWNER/ADMIN/SALES_MANAGER/SALES_REP can register a manual '
        'pós-venda milestone (TASK-201); SALES_ASSISTANT/FINANCE/READ_ONLY '
        'never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
        SystemRoleName.salesRep,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.postSaleEventRegister),
          isTrue,
          reason: '$role must be able to register a pós-venda milestone.',
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
          ).contains(Capability.postSaleEventRegister),
          isFalse,
          reason: '$role must never be able to register a pós-venda milestone.',
        );
      }
    });

    test('only OWNER/ADMIN/SALES_MANAGER can create/edit/publish/revise '
        'commercial packs (TASK-207); SALES_REP/SALES_ASSISTANT/FINANCE/'
        'READ_ONLY never can', () {
      for (final role in <SystemRoleName>[
        SystemRoleName.owner,
        SystemRoleName.admin,
        SystemRoleName.salesManager,
      ]) {
        expect(
          RolePermissionMatrix.capabilitiesFor(
            role,
          ).contains(Capability.commercialPackManage),
          isTrue,
          reason: '$role must be able to manage commercial packs.',
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
          ).contains(Capability.commercialPackManage),
          isFalse,
          reason: '$role must never manage commercial packs.',
        );
      }
    });

    test(
      'OWNER/ADMIN/SALES_MANAGER/SALES_REP can manage expedição/tracking/'
      'ocorrências (TASK-214); SALES_ASSISTANT/FINANCE/READ_ONLY never can',
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
            ).contains(Capability.shipmentManage),
            isTrue,
            reason:
                '$role must be able to manage expedição/tracking/ocorrências.',
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
            ).contains(Capability.shipmentManage),
            isFalse,
            reason: '$role must never manage expedição/tracking/ocorrências.',
          );
        }
      },
    );

    test(
      'OWNER/ADMIN/SALES_MANAGER/SALES_REP can request/cancel/convert a '
      'backorder (TASK-215); SALES_ASSISTANT/FINANCE/READ_ONLY never can',
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
            ).contains(Capability.backorderRequest),
            isTrue,
            reason: '$role must be able to request/cancel/convert a backorder.',
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
            ).contains(Capability.backorderRequest),
            isFalse,
            reason: '$role must never request/cancel/convert a backorder.',
          );
        }
      },
    );

    test(
      'only OWNER/ADMIN/SALES_MANAGER can decide (approve/reject) a backorder '
      '(TASK-215); SALES_REP/SALES_ASSISTANT/FINANCE/READ_ONLY never can',
      () {
        for (final role in <SystemRoleName>[
          SystemRoleName.owner,
          SystemRoleName.admin,
          SystemRoleName.salesManager,
        ]) {
          expect(
            RolePermissionMatrix.capabilitiesFor(
              role,
            ).contains(Capability.backorderApprove),
            isTrue,
            reason: '$role must be able to decide a backorder.',
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
            ).contains(Capability.backorderApprove),
            isFalse,
            reason: '$role must never decide a backorder.',
          );
        }
      },
    );

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
