import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'drift_database.g.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Notes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'comparison_drift'));

  @override
  int get schemaVersion => 1;

  Stream<List<Note>> watchAllNotes() => (select(notes)
        ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]))
      .watch();

  Future<int> addNote(String title, String content) {
    return into(notes).insert(
      NotesCompanion.insert(title: title, content: content),
    );
  }

  Future<bool> updateNote(int id) async {
    final changed = await (update(notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        title: Value('Updated Drift #$id'),
        content: Value('Data diperbarui pada ${DateTime.now()}'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return changed > 0;
  }

  Future<bool> deleteNote(int id) async {
    final changed = await (delete(notes)..where((t) => t.id.equals(id))).go();
    return changed > 0;
  }

  Future<void> clearNotes() => delete(notes).go();

  Future<void> seed1000() async {
    await batch((batch) {
      for (var i = 1; i <= 1000; i++) {
        batch.insert(
          notes,
          NotesCompanion.insert(
            title: 'Drift Note $i',
            content: 'Data uji 1000+ catatan',
          ),
        );
      }
    });
  }
}
