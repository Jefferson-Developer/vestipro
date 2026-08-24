/// Who can see a saved [CustomerSegment] besides its creator (TASK-053).
enum CustomerSegmentVisibility {
  /// Visible only to the user who created it.
  private,

  /// Visible to any organization member who can already see the carteira
  /// (`Capability.customerView`).
  shared,
}

extension CustomerSegmentVisibilityCode on CustomerSegmentVisibility {
  String get code {
    return switch (this) {
      CustomerSegmentVisibility.private => 'private',
      CustomerSegmentVisibility.shared => 'shared',
    };
  }

  static CustomerSegmentVisibility fromCode(String? code) {
    return switch (code) {
      'shared' => CustomerSegmentVisibility.shared,
      _ => CustomerSegmentVisibility.private,
    };
  }
}
