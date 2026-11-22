import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/book.dart';
import '../../domain/entities/plan_day.dart';
import '../../domain/entities/reading_plan.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Books, Units, Plans, PlanDays, PlanDayUnits, Progress])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For tests: pass `NativeDatabase.memory()`.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  /// Keep microsecond precision for plan dates and completion times.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      // schemaVersion 1 is the initial schema. Future versions add steps here.
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}luma.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
