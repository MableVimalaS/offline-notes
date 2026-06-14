import 'package:hive/hive.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes-enum.dart';
import 'package:offline_notes_app/features/notes/data/enum/operation-enum.dart';
import 'package:offline_notes_app/features/notes/data/models/data-sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note-model.dart';
import 'package:offline_notes_app/features/notes/data/remote/note-remote-datasource.dart';
import 'package:offline_notes_app/features/notes/services/hive-service.dart';

final NoteRemoteDataSource remoteDataSource =
    NoteRemoteDataSource();

class SyncService {
  final Box<Map> notesBox =
      Hive.box<Map>(HiveService.notesBox);

  final Box<Map> queueBox =
      Hive.box<Map>(HiveService.syncQueueBox);

  Future<void> sync() async {
    final operations = queueBox.values
        .map(
          (e) => SyncOperation.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();

    print(
      'Pending operations: ${operations.length}',
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

  final noteData =
      notesBox.get(operation.noteId);

  if (noteData == null) {
    await queueBox.delete(key);
    continue;
  }

  final note = NoteModel.fromJson(
    Map<String, dynamic>.from(noteData),
  );

  switch (operation.operationType) {
    case OperationType.create:
      await remoteDataSource.createNote(note);
      break;

    case OperationType.update:
      await remoteDataSource.updateNote(note);
      break;

    case OperationType.delete:
      await remoteDataSource.deleteNote(
        operation.noteId,
      );
      break;
  }

  await notesBox.put(
    operation.noteId,
    note.copyWith(
      syncStatus: SyncStatus.synced,
    ).toJson(),
  );

  await queueBox.delete(key);
}
  }
}