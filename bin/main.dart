import 'dart:io';

import 'package:task_cli/domain/exceptions.dart';
import 'package:task_cli/infrastructure/json_task_repository.dart';
import 'package:task_cli/presentation/menu_app.dart';

void main(List<String> arguments) {
  final repository = JsonTaskRepository('tasks.json');
  final app = MenuApp(repository);

  try {
    app.run();
  } on TaskCliException catch (e) {
    stderr.writeln('Erreur : $e');
    exit(1);
  } on FormatException catch (e) {
    stderr.writeln('Erreur de format : $e');
    exit(1);
  } on ArgumentError catch (e) {
    stderr.writeln('Erreur : ${e.message}');
    exit(1);
  }
}
