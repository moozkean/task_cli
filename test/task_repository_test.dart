import 'dart:io';

import 'package:task_cli/domain/exceptions.dart';
import 'package:task_cli/domain/priority.dart';
import 'package:task_cli/domain/repository.dart';
import 'package:task_cli/domain/task.dart';
import 'package:task_cli/infrastructure/json_task_repository.dart';
import 'package:test/test.dart';

/// A minimal in-memory [Repository] used to test domain logic in isolation,
/// without touching the filesystem. It implements the same [Repository]
/// interface as [JsonTaskRepository], which is the whole point of coding
/// against an interface rather than a concrete class.
class InMemoryTaskRepository implements Repository<Task> {
  final List<Task> _tasks = [];

  @override
  void add(Task item) => _tasks.add(item);

  @override
  List<Task> getAll() => List.unmodifiable(_tasks);

  @override
  void update(Task item) {
    final index = _tasks.indexWhere((t) => t.id == item.id);
    if (index == -1) throw TaskNotFoundException(item.id);
    _tasks[index] = item;
  }

  @override
  void delete(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    _tasks.removeAt(index);
  }

  @override
  Task? findById(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }
}

void main() {
  group('Task hierarchy', () {
    test('UrgentTask is always high priority', () {
      final task =
          UrgentTask(id: '1', title: 'Serveur en panne', reason: 'Panne critique');
      expect(task.priority, Priority.high);
      expect(task.describe(), contains('URGENT'));
    });

    test('NormalTask keeps the requested priority', () {
      final task =
          NormalTask(id: '2', title: 'Ranger le bureau', priority: Priority.low);
      expect(task.priority, Priority.low);
    });

    test('Task rejects an empty title', () {
      expect(
        () => NormalTask(id: '3', title: '   ', priority: Priority.medium),
        throwsArgumentError,
      );
    });
  });

  group('InMemoryTaskRepository', () {
    late InMemoryTaskRepository repo;

    setUp(() => repo = InMemoryTaskRepository());

    test('add then getAll returns the added task', () {
      final task = NormalTask(id: '1', title: 'Test', priority: Priority.medium);
      repo.add(task);
      expect(repo.getAll(), hasLength(1));
      expect(repo.getAll().first.id, '1');
    });

    test('findById returns null for an unknown id', () {
      expect(repo.findById('does-not-exist'), isNull);
    });

    test('delete throws TaskNotFoundException for an unknown id', () {
      expect(() => repo.delete('missing'), throwsA(isA<TaskNotFoundException>()));
    });

    test('update replaces the task with the same id', () {
      final task = NormalTask(id: '1', title: 'Test', priority: Priority.medium);
      repo.add(task);
      task.completed = true;
      repo.update(task);
      expect(repo.findById('1')!.completed, isTrue);
    });

    test('tasks sort by priority, high first', () {
      repo.add(NormalTask(id: '1', title: 'Basse', priority: Priority.low));
      repo.add(NormalTask(id: '2', title: 'Haute', priority: Priority.high));
      repo.add(NormalTask(id: '3', title: 'Moyenne', priority: Priority.medium));

      final sorted = repo.getAll().toList()..sort();
      expect(sorted.map((t) => t.id), ['2', '3', '1']);
    });
  });

  group('JsonTaskRepository', () {
    late Directory tempDir;
    late String path;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('task_cli_test_');
      path = '${tempDir.path}/tasks.json';
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('persists tasks to disk and reloads them', () {
      final repo = JsonTaskRepository(path);
      repo.add(NormalTask(id: '1', title: 'Persisté', priority: Priority.high));

      final reloaded = JsonTaskRepository(path);
      expect(reloaded.getAll(), hasLength(1));
      expect(reloaded.getAll().first.title, 'Persisté');
    });

    test('round-trips an UrgentTask including its reason', () {
      final repo = JsonTaskRepository(path);
      repo.add(UrgentTask(id: '1', title: 'Panne', reason: 'Site down'));

      final reloaded = JsonTaskRepository(path);
      final task = reloaded.findById('1') as UrgentTask;
      expect(task.reason, 'Site down');
      expect(task.priority, Priority.high);
    });

    test('deleting an unknown id throws TaskNotFoundException', () {
      final repo = JsonTaskRepository(path);
      expect(() => repo.delete('missing'), throwsA(isA<TaskNotFoundException>()));
    });
  });
}
