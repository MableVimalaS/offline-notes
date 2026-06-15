import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes_enum.dart';
import 'package:offline_notes_app/features/notes/data/enum/operation_enum.dart';
import 'package:offline_notes_app/features/notes/data/local/add_note.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/services/hive_service.dart';
import 'package:offline_notes_app/features/notes/services/sync_service.dart';

void main() {
  late NoteLocalDataSourceImpl datasource;
  late SyncService syncService;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_sync_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(HiveService.notesBox);
    await Hive.openBox<Map>(HiveService.syncQueueBox);
  });

  setUp(() {
    datasource = NoteLocalDataSourceImpl();
    syncService = SyncService();
  });

  tearDown(() async {
    await Hive.box<Map>(HiveService.notesBox).clear();
    await Hive.box<Map>(HiveService.syncQueueBox).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  final testNote = NoteModel(
    id: 'sync-note-1',
    title: 'Sync Test',
    body: 'Body',
    updatedAt: DateTime(2024),
  );

  group('SyncService.sync', () {
    test('marks note as synced after create operation succeeds', () async {
      await datasource.addNote(testNote);

      final beforeOps = await datasource.getPendingOperations();
      expect(beforeOps.length, 1);
      expect(beforeOps.first.operationType, OperationType.create);

      await syncService.sync();

      final afterOps = await datasource.getPendingOperations();
      expect(afterOps, isEmpty);

      final notes = await datasource.getAllNotes();
      expect(notes.first.syncStatus, SyncStatus.synced);
    });

    test('clears queue entry for delete operation', () async {
      await datasource.addNote(testNote);
      await datasource.deleteNote(testNote.id);

      // Queue should have: create + delete operations
      final beforeOps = await datasource.getPendingOperations();
      expect(
        beforeOps.any((o) => o.operationType == OperationType.delete),
        isTrue,
      );

      await syncService.sync();

      final afterOps = await datasource.getPendingOperations();
      expect(afterOps, isEmpty);
    });

    test('does nothing when queue is empty', () async {
      await syncService.sync();
      final ops = await datasource.getPendingOperations();
      expect(ops, isEmpty);
    });

    test('marks note as synced after update operation succeeds', () async {
      await datasource.addNote(testNote);
      // Manually sync the create so we start clean
      await syncService.sync();

      final updated = testNote.copyWith(title: 'Updated Title');
      await datasource.updateNote(updated);

      await syncService.sync();

      final notes = await datasource.getAllNotes();
      expect(notes.first.title, 'Updated Title');
      expect(notes.first.syncStatus, SyncStatus.synced);
    });
  });
}
