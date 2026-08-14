import '../domain/exceptions.dart';
import '../domain/priority.dart';
import '../domain/repository.dart';
import '../domain/task.dart';

/// Parses command-line arguments and drives a [Repository] accordingly.
///
/// Kept separate from `main()` so the whole command layer can be unit
/// tested without spawning a real process or touching real stdin/stdout.
class CliApp {
  final Repository<Task> repository;
  final String Function() idGenerator;

  CliApp(this.repository, {String Function()? idGenerator})
      : idGenerator = idGenerator ?? _defaultIdGenerator;

  static String _defaultIdGenerator() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  /// Runs a single command and returns the text that should be printed.
  String run(List<String> args) {
    if (args.isEmpty) return help();
    final command = args.first;
    final rest = args.skip(1).toList();

    switch (command) {
      case 'add':
        return _add(rest);
      case 'list':
        return _list(rest);
      case 'done':
        return _done(rest);
      case 'delete':
        return _delete(rest);
      case 'help':
        return help();
      default:
        return 'Commande inconnue: "$command". Tapez "help" pour la liste des commandes.';
    }
  }

  Map<String, String> _parseOptions(List<String> args) {
    final options = <String, String>{};
    for (final arg in args) {
      if (arg.startsWith('--') && arg.contains('=')) {
        final idx = arg.indexOf('=');
        options[arg.substring(2, idx)] = arg.substring(idx + 1);
      } else if (arg.startsWith('--')) {
        options[arg.substring(2)] = 'true';
      }
    }
    return options;
  }

  String _add(List<String> args) {
    final positional = args.where((a) => !a.startsWith('--')).toList();
    final options = _parseOptions(args);

    if (positional.isEmpty) {
      throw InvalidTaskException(
        'le titre est obligatoire. Usage: add "<titre>" [--priority=low|medium|high] [--due=AAAA-MM-JJ] ou add "<titre>" --urgent --reason="..."',
      );
    }

    final title = positional.first;
    final dueDate =
        options.containsKey('due') ? DateTime.parse(options['due']!) : null;
    final id = idGenerator();

    Task task;
    if (options['urgent'] == 'true') {
      task = UrgentTask(
        id: id,
        title: title,
        dueDate: dueDate,
        reason: options['reason'] ?? 'Non spécifiée',
      );
    } else {
      final priority = Priority.fromString(options['priority'] ?? 'medium');
      task = NormalTask(id: id, title: title, priority: priority, dueDate: dueDate);
    }

    repository.add(task);
    return 'Tâche ajoutée (id: $id): ${task.describe()}';
  }

  String _list(List<String> args) {
    final options = _parseOptions(args);
    final tasks = repository.getAll().toList();

    if (tasks.isEmpty) return 'Aucune tâche pour le moment.';

    switch (options['sort']) {
      case 'date':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'priority':
      default:
        tasks.sort();
    }

    final buffer = StringBuffer();
    for (final t in tasks) {
      buffer.writeln('${t.id}. ${t.describe()}');
    }
    return buffer.toString().trimRight();
  }

  String _done(List<String> args) {
    if (args.isEmpty) {
      throw InvalidTaskException('précisez l\'identifiant. Usage: done <id>');
    }
    final task = repository.findById(args.first);
    if (task == null) throw TaskNotFoundException(args.first);
    task.completed = true;
    repository.update(task);
    return 'Tâche ${task.id} marquée comme terminée.';
  }

  String _delete(List<String> args) {
    if (args.isEmpty) {
      throw InvalidTaskException('précisez l\'identifiant. Usage: delete <id>');
    }
    repository.delete(args.first);
    return 'Tâche ${args.first} supprimée.';
  }

  String help() => '''
Task.CLI — gestionnaire de tâches en ligne de commande

Commandes disponibles :
  add "<titre>" [--priority=low|medium|high] [--due=AAAA-MM-JJ]
  add "<titre>" --urgent --reason="<raison>" [--due=AAAA-MM-JJ]
  list [--sort=priority|date]
  done <id>
  delete <id>
  help
''';
}
