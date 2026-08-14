import 'dart:convert';
import 'dart:io';

import '../domain/exceptions.dart';
import '../domain/repository.dart';
import '../domain/task.dart';

/// Concrete implementation of [Repository<Task>] that stores tasks in a
/// JSON file on disk.
///
/// Features:
/// - Automatic lazy-loading: the file is only read when needed
/// - In-memory caching: repeated queries do not re-read the file
/// - Formatted output: the JSON file is human-readable with indentation
/// - Typed exceptions: IO errors become [StorageException]
///
/// The JSON file format:
/// ```json
/// [
///   {
///     "id": "1692028934567890",
///     "title": "Fix login bug",
///     "priority": "high",
///     "dueDate": "2026-08-15T00:00:00.000Z",
///     "completed": false,
///     "createdAt": "2026-08-14T10:00:00.000Z",
///     "type": "normal"
///   }
/// ]
/// ```
class JsonTaskRepository implements Repository<Task> {
  final String filePath;
  List<Task>? _cache;

  JsonTaskRepository(this.filePath);

  List<Task> _load() {
    if (_cache != null) return _cache!;

    final file = File(filePath);
    if (!file.existsSync()) {
      _cache = <Task>[];
      return _cache!;
    }

    try {
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) {
        _cache = <Task>[];
        return _cache!;
      }
      final decoded = jsonDecode(content) as List<dynamic>;
      _cache =
          decoded.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
      return _cache!;
    } catch (e) {
      throw StorageException('lecture du fichier "$filePath" impossible ($e).');
    }
  }

  void _persist() {
    try {
      final file = File(filePath);
      final data = _cache!.map((t) => t.toJson()).toList();
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
    } catch (e) {
      throw StorageException('écriture du fichier "$filePath" impossible ($e).');
    }
  }

  @override
  void add(Task item) {
    final tasks = _load();
    if (tasks.any((t) => t.id == item.id)) {
      throw InvalidTaskException('un identifiant "${item.id}" existe déjà.');
    }
    tasks.add(item);
    _persist();
  }

  @override
  List<Task> getAll() => List.unmodifiable(_load());

  @override
  void update(Task item) {
    final tasks = _load();
    final index = tasks.indexWhere((t) => t.id == item.id);
    if (index == -1) throw TaskNotFoundException(item.id);
    tasks[index] = item;
    _persist();
  }

  @override
  void delete(String id) {
    final tasks = _load();
    final index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) throw TaskNotFoundException(id);
    tasks.removeAt(index);
    _persist();
  }

  @override
  Task? findById(String id) {
    for (final t in _load()) {
      if (t.id == id) return t;
    }
    return null;
  }
}