import 'package:hive/hive.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes_enum.dart';
import 'package:offline_notes_app/features/notes/data/enum/operation_enum.dart';
import 'package:offline_notes_app/features/notes/data/local/note_local_datasource.dart';
import 'package:offline_notes_app/features/notes/data/models/data_sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/services/hive_service.dart';

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final Box<Map> notesBox = Hive.box<Map>(HiveService.notesBox);
  final Box<Map> queueBox = Hive.box<Map>(HiveService.syncQueueBox);

  @override
  Future<void> addNote(NoteModel note) async {
    await notesBox.put(note.id, note.toJson());

    // Queue a create operation for remote sync.
    final operation = SyncOperation(
      noteId: note.id,
      operationType: OperationType.create,
      createdAt: DateTime.now(),
    );
    await queueBox.add(operation.toJson());
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await notesBox.put(note.id, note.toJson());

    final operation = SyncOperation(
      noteId: note.id,
      operationType: OperationType.update,
      createdAt: DateTime.now(),
    );
    await queueBox.add(operation.toJson());
  }

  @override
  Future<void> deleteNote(String id) async {
    await notesBox.delete(id);

    // Queue a delete operation so the remote server is notified on next sync.
    final operation = SyncOperation(
      noteId: id,
      operationType: OperationType.delete,
      createdAt: DateTime.now(),
    );
    await queueBox.add(operation.toJson());
  }

  @override
  Future<List<NoteModel>> getAllNotes() async {
    return notesBox.values
        .map((e) => NoteModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    return queueBox.values
        .map((e) => SyncOperation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
  
@override
  Future<void> resolveConflict(
    String noteId, {
    required bool keepLocal,
  }) async {
    final localData = notesBox.get(noteId);
    if (localData == null) return;

    final local = NoteModel.fromJson(Map<String, dynamic>.from(localData));

    if (keepLocal) {
      await notesBox.put(
        noteId,
        NoteModel(
          id: local.id,
          title: local.title,
          body: local.body,
          updatedAt: local.updatedAt,
          lastSyncedAt: local.lastSyncedAt,
          syncStatus: SyncStatus.pending,
        ).toJson(),
      );
      final operation = SyncOperation(
        noteId: noteId,
        operationType: OperationType.update,
        createdAt: DateTime.now(),
      );
      await queueBox.add(operation.toJson());
    } else {
      await notesBox.put(
        noteId,
        NoteModel(
          id: local.id,
          title: local.serverTitle ?? local.title,
          body: local.serverBody ?? local.body,
          updatedAt: local.serverUpdatedAt ?? local.updatedAt,
          syncStatus: SyncStatus.synced,
          lastSyncedAt: DateTime.now(),
        ).toJson(),
      );
      final keysToDelete = <dynamic>[];
      for (final qKey in queueBox.keys) {
        final qData = queueBox.get(qKey);
        if (qData == null) continue;
        final op = SyncOperation.fromJson(Map<String, dynamic>.from(qData));
        if (op.noteId == noteId) keysToDelete.add(qKey);
      }
      for (final k in keysToDelete) {
        await queueBox.delete(k);
      }
    }
  }
}
