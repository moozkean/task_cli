import 'dart:io';

import '../domain/exceptions.dart';
import '../domain/priority.dart';
import '../domain/repository.dart';
import '../domain/task.dart';

/// Interactive menu-driven application for task management.
///
/// Provides a user-friendly interface with menus and prompts instead of
/// command-line arguments. This is the main interactive UI for end users.
class MenuApp {
  final Repository<Task> repository;
  final String Function() idGenerator;

  MenuApp(this.repository, {String Function()? idGenerator})
      : idGenerator = idGenerator ?? _defaultIdGenerator;

  static String _defaultIdGenerator() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  /// Main loop of the application.
  void run() {
    print('\n${'=' * 40}');
    print('GESTIONNAIRE DE TÂCHES');
    print('${'=' * 40}\n');

    while (true) {
      _showMainMenu();
      final choice = stdin.readLineSync()?.trim() ?? '';

      try {
        switch (choice) {
          case '1':
            _addTask();
            break;
          case '2':
            _listTasks();
            break;
          case '3':
            _markTaskDone();
            break;
          case '4':
            _deleteTask();
            break;
          case '5':
            print('\nAu revoir !\n');
            return;
          default:
            print('❌ Choix invalide. Veuillez réessayer.\n');
        }
      } on TaskCliException catch (e) {
        print('❌ Erreur : $e\n');
      } on FormatException catch (e) {
        print('❌ Erreur de format : $e\n');
      } catch (e) {
        print('❌ Erreur inattendue : $e\n');
      }
    }
  }

  void _showMainMenu() {
    print('${'=' * 40}');
    print('GESTIONNAIRE DE TÂCHES');
    print('${'=' * 40}');
    print('1. Ajouter une tâche');
    print('2. Lister les tâches');
    print('3. Terminer une tâche');
    print('4. Supprimer une tâche');
    print('5. Quitter');
    print('${'=' * 40}');
    stdout.write('Votre choix : ');
  }

  void _addTask() {
    print('\n--- Ajouter une tâche ---');
    stdout.write('Titre de la tâche : ');
    final title = stdin.readLineSync()?.trim() ?? '';

    if (title.isEmpty) {
      throw InvalidTaskException('le titre ne peut pas être vide.');
    }

    print('\nType de tâche :');
    print('1. Normal');
    print('2. Urgent');
    stdout.write('Votre choix (1 ou 2) : ');
    final typeChoice = stdin.readLineSync()?.trim() ?? '';

    final id = idGenerator();
    DateTime? dueDate;
    Task task;

    if (typeChoice == '2') {
      // Urgent task
      stdout.write('Raison de l\'urgence : ');
      final reason = stdin.readLineSync()?.trim() ?? 'Non spécifiée';
      
      stdout.write('Date limite (AAAA-MM-JJ, optionnel) : ');
      final dateStr = stdin.readLineSync()?.trim();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          dueDate = DateTime.parse(dateStr);
        } catch (e) {
          throw FormatException('Date invalide. Format : AAAA-MM-JJ');
        }
      }

      task = UrgentTask(
        id: id,
        title: title,
        dueDate: dueDate,
        reason: reason,
      );
    } else {
      // Normal task
      print('\nPriorité :');
      print('1. Basse');
      print('2. Moyenne');
      print('3. Haute');
      stdout.write('Votre choix (1, 2 ou 3) : ');
      final priorityChoice = stdin.readLineSync()?.trim() ?? '2';

      final priority = switch (priorityChoice) {
        '1' => Priority.low,
        '2' => Priority.medium,
        '3' => Priority.high,
        _ => throw ArgumentError('Choix de priorité invalide'),
      };

      stdout.write('Date limite (AAAA-MM-JJ, optionnel) : ');
      final dateStr = stdin.readLineSync()?.trim();
      if (dateStr != null && dateStr.isNotEmpty) {
        try {
          dueDate = DateTime.parse(dateStr);
        } catch (e) {
          throw FormatException('Date invalide. Format : AAAA-MM-JJ');
        }
      }

      task = NormalTask(
        id: id,
        title: title,
        priority: priority,
        dueDate: dueDate,
      );
    }

    repository.add(task);
    print('✅ Tâche ajoutée (id: $id)\n');
  }

  void _listTasks() {
    print('\n--- Liste des tâches ---');
    
    print('1. Sans tri');
    print('2. Trier par priorité');
    print('3. Trier par date limite');
    stdout.write('Votre choix : ');
    final choice = stdin.readLineSync()?.trim() ?? '2';

    final tasks = repository.getAll().toList();

    if (tasks.isEmpty) {
      print('Aucune tâche pour le moment.\n');
      return;
    }

    switch (choice) {
      case '1':
        break; // No sorting
      case '2':
      case '':
        tasks.sort(); // Default: priority
        break;
      case '3':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      default:
        print('Choix invalide. Tri par défaut (priorité).\n');
        tasks.sort();
    }

    print('');
    for (final task in tasks) {
      final status = task.completed ? '✅' : '⭕';
      print('$status ${task.id} - ${task.describe()}');
    }
    print('');
  }

  void _markTaskDone() {
    print('\n--- Terminer une tâche ---');
    final tasks = repository.getAll().toList();

    if (tasks.isEmpty) {
      print('Aucune tâche pour le moment.\n');
      return;
    }

    print('Tâches :');
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final status = task.completed ? '✅' : '⭕';
      print('${i + 1}. $status ${task.describe()}');
    }

    stdout.write('Sélectionner la tâche (numéro) : ');
    final choice = stdin.readLineSync()?.trim();

    if (choice == null || choice.isEmpty) {
      throw InvalidTaskException('choix invalide.');
    }

    final index = int.tryParse(choice) ?? -1;
    if (index < 1 || index > tasks.length) {
      throw InvalidTaskException('numéro invalide.');
    }

    final task = tasks[index - 1];
    task.completed = true;
    repository.update(task);
    print('✅ Tâche ${task.id} marquée comme terminée.\n');
  }

  void _deleteTask() {
    print('\n--- Supprimer une tâche ---');
    final tasks = repository.getAll().toList();

    if (tasks.isEmpty) {
      print('Aucune tâche pour le moment.\n');
      return;
    }

    print('Tâches :');
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      print('${i + 1}. ${task.describe()}');
    }

    stdout.write('Sélectionner la tâche à supprimer (numéro) : ');
    final choice = stdin.readLineSync()?.trim();

    if (choice == null || choice.isEmpty) {
      throw InvalidTaskException('choix invalide.');
    }

    final index = int.tryParse(choice) ?? -1;
    if (index < 1 || index > tasks.length) {
      throw InvalidTaskException('numéro invalide.');
    }

    final task = tasks[index - 1];
    repository.delete(task.id);
    print('✅ Tâche ${task.id} supprimée.\n');
  }
}
