# Task.CLI 🚀

Une application en ligne de commande (CLI) performante, robuste et bien structurée
pour gérer des tâches productives. Développée entièrement en **Dart pur** (sans Flutter),
avec une **Clean Architecture** stricte pour garantir la testabilité et la maintenabilité.

## Architecture

Le projet suit les principes de Clean Architecture avec une séparation nette des responsabilités :

```
Task.CLI
├── Domain (Règles métier)
│   ├── Task (entités: NormalTask, UrgentTask)
│   ├── Priority (énumération)
│   ├── Repository (interface de contrat)
│   └── Exceptions (exceptions métier)
├── Infrastructure (Persistence)
│   └── JsonTaskRepository (implémentation avec fichier JSON)
└── Presentation (Interface interactive)
    ├── MenuApp (menu interactif avec boucle)
    └── CliApp (CLI à arguments - pour tests)
```

### Caractéristiques principales

- ✅ **Aucune dépendance externe** — Dart pur, sans Flutter
- ✅ **Testable** — Logique métier isolée et facilement testable
- ✅ **SOLID** — Chaque couche a une responsabilité unique
- ✅ **Persistance** — Données stockées en JSON
- ✅ **Exceptions typées** — Gestion d'erreur explicite et prévisible

## Prérequis

- [Dart SDK](https://dart.dev/get-dart) ≥ 3.0.0
- (Optionnel) [Git](https://git-scm.com/) pour le versioning

## Installation

```bash
# Cloner le repository
git clone https://github.com/moozkean/task_cli.git
cd task_cli

# Installer les dépendances
dart pub get
```

## Utilisation

### Lancer l'application

```bash
dart run bin/main.dart
```

L'application affiche un **menu interactif** :

```
========================================
GESTIONNAIRE DE TÂCHES
========================================
1. Ajouter une tâche
2. Lister les tâches
3. Terminer une tâche
4. Supprimer une tâche
5. Quitter
========================================
Votre choix :
```

### Menu 1️⃣ - Ajouter une tâche

- **Titre** : Le titre de la tâche
- **Type** : Normal ou Urgent
  - **Normal** : Choisissez la priorité (Basse, Moyenne, Haute)
  - **Urgent** : Toujours priorité Haute + raison
- **Date limite** (optionnel) : Format AAAA-MM-JJ

### Menu 2️⃣ - Lister les tâches

Trois options de tri :
1. **Sans tri** : Ordre d'ajout
2. **Trier par priorité** : Urgentes et haute en premier
3. **Trier par date** : Dates les plus proches en premier

### Menu 3️⃣ - Terminer une tâche

- Affiche la liste des tâches
- Sélectionnez le numéro de la tâche à terminer
- Marque la tâche comme ✅ complétée

### Menu 4️⃣ - Supprimer une tâche

- Affiche la liste des tâches
- Sélectionnez le numéro de la tâche à supprimer
- Tâche supprimée définitivement

## Tests

```bash
# Exécuter tous les tests
dart test

# Exécuter les tests avec détails verbose
dart test -v
```

## Structure du projet

```
task_cli/
├── bin/
│   └── main.dart           # Point d'entrée de l'application
├── lib/
│   ├── domain/             # Logique métier et entités
│   │   ├── task.dart       # Classe Task et ses sous-classes
│   │   ├── priority.dart   # Énumération des priorités
│   │   ├── repository.dart # Interface Repository<T>
│   │   └── exceptions.dart # Exceptions métier
│   ├── infrastructure/     # Implémentation concrète
│   │   └── json_task_repository.dart
│   └── presentation/       # Couche interface
│       ├── menu_app.dart   # Menu interactif (UI principale)
│       └── cli_app.dart    # CLI à arguments (pour tests)
├── test/
│   └── task_repository_test.dart
├── pubspec.yaml            # Configuration Dart
└── README.md               # Ce fichier
```

## Exemple de flux d'utilisation

```
$ dart run bin/main.dart

========================================
GESTIONNAIRE DE TÂCHES
========================================
1. Ajouter une tâche
2. Lister les tâches
3. Terminer une tâche
4. Supprimer une tâche
5. Quitter
========================================
Votre choix : 1

--- Ajouter une tâche ---
Titre de la tâche : Analyser les logs

Type de tâche :
1. Normal
2. Urgent
Votre choix (1 ou 2) : 1

Priorité :
1. Basse
2. Moyenne
3. Haute
Votre choix (1, 2 ou 3) : 3

Date limite (AAAA-MM-JJ, optionnel) : 2026-08-15
✅ Tâche ajoutée (id: 1692028934567890)
```

Les tâches sont automatiquement persistées dans `tasks.json` à la racine du projet.

## Tests

```bash
# Exécuter tous les tests
dart test

# Exécuter les tests avec détails verbose
dart test -v
```

**Note** : La classe `CliApp` (CLI à arguments) est conservée pour les tests unitaires. Les tests vérifient la logique métier de manière isolée, indépendante de l'interface utilisée.

## Lancer les tests

```bash
dart test
```

Le fichier `test/task_repository_test.dart` couvre :

- la hiérarchie `Task` / `NormalTask` / `UrgentTask` (héritage, validation) ;
- le contrat `Repository<T>` via une implémentation en mémoire ;
- la persistance JSON réelle sur disque, y compris pour les tâches
  urgentes et la gestion des erreurs (`TaskNotFoundException`).

## Structure du projet

```
task_cli/
├── bin/
│   └── main.dart                     # Point d'entrée
├── lib/
│   ├── domain/
│   │   ├── exceptions.dart           # Exceptions personnalisées
│   │   ├── priority.dart             # Enum Priority
│   │   ├── repository.dart           # Interface générique Repository<T>
│   │   └── task.dart                 # Task (abstraite), NormalTask, UrgentTask
│   ├── infrastructure/
│   │   └── json_task_repository.dart # Persistance JSON
│   └── presentation/
│       └── cli_app.dart              # Parsing et dispatch des commandes
├── test/
│   └── task_repository_test.dart
├── pubspec.yaml
└── README.md
```

## Points techniques

- **Classes abstraites et héritage** : `Task` est abstraite ;
  `UrgentTask extends Task` et impose toujours une priorité haute.
- **Interface** : `Repository<T>` est un contrat pur, implémenté par
  `JsonTaskRepository` (et par un repository en mémoire dans les tests).
- **Génériques** : `Repository<T>` est générique et instancié en
  `Repository<Task>`.
- **Exceptions personnalisées** : `TaskNotFoundException`,
  `InvalidTaskException`, `StorageException`.
- **Tests unitaires** : 10 tests avec le package `test`.
# task_cli(1)
