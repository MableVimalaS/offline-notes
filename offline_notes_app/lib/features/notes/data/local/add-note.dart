import 'package:hive/hive.dart';
import 'package:offline_notes_app/features/notes/data/enum/operation-enum.dart';
import 'package:offline_notes_app/features/notes/data/local/note-local-datasources.dart';
import 'package:offline_notes_app/features/notes/data/models/data-sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note-model.dart';
import 'package:offline_notes_app/features/notes/services/hive-service.dart';



class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  final Box<Map> notesBox =
      Hive.box<Map>(HiveService.notesBox);
      

  final Box<Map> queueBox =
      Hive.box<Map>(HiveService.syncQueueBox);

  @override
  Future<void> addNote(NoteModel note) async {
    await notesBox.put(
      note.id,
      note.toJson(),
    );
    

   for (final key in queueBox.keys) {
  final data = queueBox.get(key);

  if (data == null) continue;

  final operation = SyncOperation.fromJson(
    Map<String, dynamic>.from(data),
  );

  print(
    'Syncing ${operation.operationType.name} for ${operation.noteId}',
  );

  await queueBox.delete(key);
}


  }

  @override
  Future<List<NoteModel>> getAllNotes() async {
    return notesBox.values
        .map(
          (e) => NoteModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  @override
  Future<void> updateNote(NoteModel note) async {
    await notesBox.put(
      note.id,
      note.toJson(),
    );

    final operation = SyncOperation(
      noteId: note.id,
      operationType: OperationType.update,
      createdAt: DateTime.now(),
    );

    await queueBox.add(
      operation.toJson(),
    );
  }

  @override
Future<void> deleteNote(String id) async {
  await notesBox.delete(id);
}
  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    return queueBox.values
        .map(
          (e) => SyncOperation.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }
}