import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:offline_notes_app/features/notes/data/enum/notes_enum.dart';
import 'package:offline_notes_app/features/notes/data/enum/operation_enum.dart';
import 'package:offline_notes_app/features/notes/data/models/data_sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/data/remote/note_remote_datasource.dart';
import 'package:offline_notes_app/features/notes/services/hive_service.dart';

final _log = Logger();

class SyncService {
  final Box<Map> notesBox = Hive.box<Map>(HiveService.notesBox);
  final Box<Map> queueBox = Hive.box<Map>(HiveService.syncQueueBox);
  final NoteRemoteDataSource remoteDataSource = NoteRemoteDataSource();

  Future<void> sync() async {
    final keys = queueBox.keys.toList();
    _log.d('Pending sync operations: ${keys.length}');

    for (final key in keys) {
      final data = queueBox.get(key);
      if (data == null) continue;

      final operation = SyncOperation.fromJson(
        Map<String, dynamic>.from(data),
      );
      _log.d(
        'Syncing ${operation.operationType.name} for ${operation.noteId}',
      );

      try {
        switch (operation.operationType) {
          case OperationType.delete:
            // Note is already removed locally; notify the remote server.
            await remoteDataSource.deleteNote(operation.noteId);
            await queueBox.delete(key);

          case OperationType.create:
          case OperationType.update:
            final noteData = notesBox.get(operation.noteId);
            if (noteData == null) {
              // Note was removed before sync could run — skip safely.
              await queueBox.delete(key);
              break;
            }
            final note = NoteModel.fromJson(
              Map<String, dynamic>.from(noteData),
            );

            if (operation.operationType == OperationType.create) {
              await remoteDataSource.createNote(note);
            } else {
              await remoteDataSource.updateNote(note);
            }

            await notesBox.put(
              note.id,
              note
                  .copyWith(
                    syncStatus: SyncStatus.synced,
                    lastSyncedAt: DateTime.now(),
                  )
                  .toJson(),
            );
            await queueBox.delete(key);
        }
      } catch (e) {
        // Leave failed operations in the queue for retry on next sync.
        _log.e(
          'Sync failed for ${operation.noteId} — will retry',
          error: e,
        );
      }
    }
  }
}
