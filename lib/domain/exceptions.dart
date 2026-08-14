/// Base class for every custom exception thrown by Task.CLI.
///
/// Catching [TaskCliException] in `main()` lets us show clean, French
/// error messages instead of raw stack traces for anything predictable.
abstract class TaskCliException implements Exception {
  final String message;

  TaskCliException(this.message);

  @override
  String toString() => message;
}

/// Thrown when a requested task cannot be found in the repository.
class TaskNotFoundException extends TaskCliException {
  TaskNotFoundException(String id)
      : super('Aucune tâche trouvée avec l\'identifiant "$id".');
}

/// Thrown when task data provided by the user (or read from storage) is
/// invalid, e.g. a duplicate id or a missing required field.
class InvalidTaskException extends TaskCliException {
  InvalidTaskException(String reason) : super('Tâche invalide : $reason');
}

/// Thrown when reading from or writing to the JSON storage file fails.
class StorageException extends TaskCliException {
  StorageException(String reason) : super('Erreur de stockage : $reason');
}
