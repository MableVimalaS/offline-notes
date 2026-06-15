import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes_enum.dart';
import 'package:offline_notes_app/features/notes/data/enum/operation_enum.dart';
import 'package:offline_notes_app/features/notes/data/local/add_note.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/services/hive_service.dart';

void main() {
  late NoteLocalDataSourceImpl datasource;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(HiveService.notesBox);
    await Hive.openBox<Map>(HiveService.syncQueueBox);
  });

  setUp(() {
    datasource = NoteLocalDataSourceImpl();
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
    id: 'note-1',
    title: 'Hello',
    body: 'World',
    updatedAt: DateTime(2024),
  );

  group('addNote', () {
    test('persists note and queues a create operation', () async {
      await datasource.addNote(testNote);

      final notes = await datasource.getAllNotes();
      expect(notes.length, 1);
      expect(notes.first.id, 'note-1');

      final ops = await datasource.getPendingOperations();
      expect(ops.length, 1);
      expect(ops.first.operationType, OperationType.create);
      expect(ops.first.noteId, 'note-1');
    });

    test('does NOT clear existing queued operations', () async {
      final other = NoteModel(
        id: 'note-2',
        title: 'Other',
        body: '',
        updatedAt: DateTime(2024),
      );
      await datasource.addNote(other);
      await datasource.addNote(testNote);

      final ops = await datasource.getPendingOperations();
      expect(ops.length, 2);
    });
  });

  group('updateNote', () {
    test('updates note and queues an update operation', () async {
      await datasource.addNote(testNote);
      final updated = testNote.copyWith(title: 'Updated');
      await datasource.updateNote(updated);

      final notes = await datasource.getAllNotes();
      expect(notes.first.title, 'Updated');

      final ops = await datasource.getPendingOperations();
      final updateOps =
          ops.where((o) => o.operationType == OperationType.update).toList();
      expect(updateOps.length, 1);
    });
  });

  group('deleteNote', () {
    test('removes note and queues a delete operation', () async {
      await datasource.addNote(testNote);
      await datasource.deleteNote(testNote.id);

      final notes = await datasource.getAllNotes();
      expect(notes, isEmpty);

      final ops = await datasource.getPendingOperations();
      final deleteOps =
          ops.where((o) => o.operationType == OperationType.delete).toList();
      expect(deleteOps.length, 1);
      expect(deleteOps.first.noteId, testNote.id);
    });
  });

  group('getAllNotes', () {
    test('returns empty list when no notes stored', () async {
      final notes = await datasource.getAllNotes();
      expect(notes, isEmpty);
    });

    test('returns all stored notes', () async {
      await datasource.addNote(testNote);
      await datasource.addNote(
        testNote.copyWith(id: 'note-2', title: 'Second'),
      );

      final notes = await datasource.getAllNotes();
      expect(notes.length, 2);
    });
  });

  group('getPendingOperations', () {
    test('returns empty when queue is empty', () async {
      final ops = await datasource.getPendingOperations();
      expect(ops, isEmpty);
    });

    test('note with pending syncStatus stays pending until synced', () async {
      await datasource.addNote(testNote);
      final notes = await datasource.getAllNotes();
      expect(notes.first.syncStatus, SyncStatus.pending);
    });
  });
}
