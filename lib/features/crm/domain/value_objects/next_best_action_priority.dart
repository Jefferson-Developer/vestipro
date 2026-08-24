enum NextBestActionPriority { high, medium, low }

extension NextBestActionPriorityRank on NextBestActionPriority {
  int get rank {
    return switch (this) {
      NextBestActionPriority.high => 3,
      NextBestActionPriority.medium => 2,
      NextBestActionPriority.low => 1,
    };
  }
}
