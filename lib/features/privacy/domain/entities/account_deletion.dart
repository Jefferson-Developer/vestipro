final class AccountDeletionReceipt {
  const AccountDeletionReceipt({
    required this.anonymizedRecords,
    required this.deletedRecords,
  });

  final int anonymizedRecords;
  final int deletedRecords;
}
