/// Represents how urgently a task should be handled.
enum Priority {
  low,
  medium,
  high;

  /// Parses a priority from a case-insensitive string such as the one
  /// passed on the command line (`--priority=high`).
  ///
  /// Throws an [ArgumentError] if [value] is not a recognized priority.
  static Priority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return Priority.low;
      case 'medium':
        return Priority.medium;
      case 'high':
        return Priority.high;
      default:
        throw ArgumentError(
          'Priorité inconnue: "$value". Utilisez low, medium ou high.',
        );
    }
  }

  /// Numeric weight used for sorting (higher value = more urgent).
  int get weight {
    switch (this) {
      case Priority.low:
        return 0;
      case Priority.medium:
        return 1;
      case Priority.high:
        return 2;
    }
  }
}

