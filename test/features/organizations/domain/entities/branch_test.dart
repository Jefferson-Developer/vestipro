import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('Branch', () {
    final createdAt = DateTime.utc(2026, 1, 1);
    final updatedAt = DateTime.utc(2026, 1, 2);
    const address = BranchAddress(
      street: 'Rua XV de Novembro',
      number: '100',
      neighborhood: 'Centro',
      city: 'Blumenau',
      state: 'SC',
      postalCode: '89010-000',
      country: 'BR',
    );

    Branch buildBranch({
      String id = 'branch-1',
      String organizationId = 'org-1',
      String companyId = 'company-1',
    }) {
      return Branch(
        id: id,
        organizationId: organizationId,
        companyId: companyId,
        name: 'Loja Blumenau',
        type: BranchType.store,
        address: address,
        status: BranchStatus.active,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: updatedAt,
        updatedBy: 'user-1',
      );
    }

    test('two branches with the same field values are equal', () {
      expect(buildBranch(), buildBranch());
    });

    test('branches with different ids are not equal', () {
      expect(buildBranch(id: 'branch-1'), isNot(buildBranch(id: 'branch-2')));
    });

    test('branches from different companies are not equal even with the same '
        'id', () {
      expect(
        buildBranch(companyId: 'company-1'),
        isNot(buildBranch(companyId: 'company-2')),
      );
    });

    test('copyWith produces a new instance without mutating the original '
        'organizationId/companyId', () {
      final original = buildBranch();
      final copy = original.copyWith(name: 'Loja Blumenau Centro');

      expect(original.organizationId, 'org-1');
      expect(original.companyId, 'company-1');
      expect(copy.organizationId, 'org-1');
      expect(copy.companyId, 'company-1');
      expect(copy.name, 'Loja Blumenau Centro');
      expect(original, isNot(copy));
    });

    test('address defaults to null (a showroom without a filled address)', () {
      final branch = Branch(
        id: 'branch-2',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Showroom São Paulo',
        type: BranchType.showroom,
        status: BranchStatus.active,
        version: 1,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
      );

      expect(branch.address, isNull);
      expect(branch.type, BranchType.showroom);
    });

    test('deletedAt is null by default (branch not soft-deleted)', () {
      expect(buildBranch().deletedAt, isNull);
    });

    test('supports multiple branches under the same company', () {
      final branchA = buildBranch(id: 'branch-a');
      final branchB = buildBranch(id: 'branch-b');

      expect(branchA.companyId, branchB.companyId);
      expect(branchA, isNot(branchB));
    });
  });
}
