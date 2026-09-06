import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/privacy/privacy.dart';

void main() {
  test('exige frase exata antes de chamar o backend', () async {
    final repository = _Repository();
    final cleaner = _Cleaner();
    final result = await RequestAccountDeletion(repository, cleaner)(
      organizationId: 'org-a',
      confirmation: 'excluir',
    );
    expect(result, isA<AppFailure<AccountDeletionReceipt>>());
    expect(repository.called, isFalse);
    expect(cleaner.called, isFalse);
  });

  test(
    'solicita no servidor e limpa dados locais somente após sucesso',
    () async {
      final repository = _Repository();
      final cleaner = _Cleaner();
      final result = await RequestAccountDeletion(repository, cleaner)(
        organizationId: 'org-a',
        confirmation: RequestAccountDeletion.confirmationPhrase,
      );
      expect(result, isA<AppSuccess<AccountDeletionReceipt>>());
      expect(repository.called, isTrue);
      expect(cleaner.called, isTrue);
    },
  );
}

final class _Repository implements AccountDeletionRepository {
  bool called = false;

  @override
  Future<AppResult<AccountDeletionReceipt>> requestDeletion({
    required String organizationId,
    required String confirmation,
  }) async {
    called = true;
    return const AppSuccess<AccountDeletionReceipt>(
      AccountDeletionReceipt(anonymizedRecords: 3, deletedRecords: 4),
    );
  }
}

final class _Cleaner implements AccountDeletionLocalCleaner {
  bool called = false;

  @override
  Future<AppResult<void>> clear() async {
    called = true;
    return const AppSuccess<void>(null);
  }
}
