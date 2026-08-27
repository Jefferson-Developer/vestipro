import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/inventory/inventory.dart';

class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  group('Warehouse use cases', () {
    late _MockWarehouseRepository repository;
    late GetWarehousesByCompanyUseCase getByCompany;
    late GetActiveWarehousesUseCase getActive;

    setUp(() {
      repository = _MockWarehouseRepository();
      getByCompany = GetWarehousesByCompanyUseCase(repository);
      getActive = GetActiveWarehousesUseCase(repository);
    });

    final warehouses = <Warehouse>[
      Warehouse(
        id: 'wh-central',
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: null,
        code: 'CD-01',
        name: 'CD Central',
        type: WarehouseType.distributionCenter,
        isActive: true,
        priority: 0,
        createdAt: DateTime.utc(2026, 8, 27),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 8, 27),
        updatedBy: 'owner-1',
        version: 1,
        syncStatus: 'synced',
      ),
      Warehouse(
        id: 'wh-branch',
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: 'branch-1',
        code: 'LOJA-01',
        name: 'Loja Centro',
        type: WarehouseType.store,
        isActive: false,
        priority: 1,
        createdAt: DateTime.utc(2026, 8, 27),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 8, 27),
        updatedBy: 'owner-1',
        version: 1,
        syncStatus: 'synced',
      ),
    ];

    test('GetWarehousesByCompany delegates branch-aware lookups', () async {
      when(
        () => repository.listByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
          branchId: 'branch-1',
        ),
      ).thenAnswer((_) async => AppSuccess<List<Warehouse>>(warehouses));

      final result = await getByCompany(
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: 'branch-1',
      );

      expect(result, isA<AppSuccess<List<Warehouse>>>());
      verify(
        () => repository.listByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
          branchId: 'branch-1',
        ),
      ).called(1);
    });

    test(
      'GetActiveWarehouses returns repository-filtered active warehouses',
      () async {
        when(
          () => repository.listActive(
            organizationId: 'org-1',
            companyId: 'company-1',
            branchId: null,
          ),
        ).thenAnswer(
          (_) async =>
              AppSuccess<List<Warehouse>>(<Warehouse>[warehouses.first]),
        );

        final result = await getActive(
          organizationId: 'org-1',
          companyId: 'company-1',
        );

        expect((result as AppSuccess<List<Warehouse>>).value, <Warehouse>[
          warehouses.first,
        ]);
        verify(
          () => repository.listActive(
            organizationId: 'org-1',
            companyId: 'company-1',
            branchId: null,
          ),
        ).called(1);
      },
    );
  });
}
