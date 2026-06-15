import 'package:hive/hive.dart';
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
}
