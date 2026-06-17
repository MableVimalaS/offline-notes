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
    await _detectConflicts();
    await _pushPending();
    await _pullNewNotes();
  }

  Future<void> _detectConflicts() async {
    try {
      final serverNotes = await remoteDataSource.fetchNotes();
      final serverMap = {
        for (final n in serverNotes) n['id'] as String: n,
      };

      for (final key in notesBox.keys.toList()) {
        final localData = notesBox.get(key);
        if (localData == null) continue;

        final local = NoteModel.fromJson(Map<String, dynamic>.from(localData));

        if (local.syncStatus != SyncStatus.pending) continue;
        if (local.lastSyncedAt == null) continue;

        final serverData = serverMap[local.id];
        if (serverData == null) continue;

        final serverUpdatedAt =
            DateTime.parse(serverData['updatedAt'] as String);

        if (serverUpdatedAt.isAfter(local.lastSyncedAt!)) {
          _log.d('Conflict detected for ${local.id}');
          await notesBox.put(
            local.id,
            local
                .copyWith(
                  syncStatus: SyncStatus.conflict,
                  serverTitle: serverData['title'] as String,
                  serverBody: serverData['body'] as String? ?? '',
                  serverUpdatedAt: serverUpdatedAt,
                )
                .toJson(),
          );
        }
      }
    } catch (e) {
      _log.e('Conflict detection failed — continuing sync', error: e);
    }
  }

  Future<void> _pushPending() async {
    final keys = queueBox.keys.toList();
    _log.d('Pending sync operations: ${keys.length}');

    for (final key in keys) {
      final data = queueBox.get(key);
      if (data == null) continue;

      final operation = SyncOperation.fromJson(
        Map<String, dynamic>.from(data),
      );

      final noteData = notesBox.get(operation.noteId);
      if (noteData != null) {
        final note = NoteModel.fromJson(Map<String, dynamic>.from(noteData));
        if (note.syncStatus == SyncStatus.conflict) continue;
      }

      _log.d('Syncing ${operation.operationType.name} for ${operation.noteId}');

      try {
        switch (operation.operationType) {
          case OperationType.delete:
            await remoteDataSource.deleteNote(operation.noteId);
            await queueBox.delete(key);

          case OperationType.create:
          case OperationType.update:
            if (noteData == null) {
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
        _log.e('Sync failed for ${operation.noteId} — will retry', error: e);
      }
    }
  }

  Future<void> _pullNewNotes() async {
    try {
      final serverNotes = await remoteDataSource.fetchNotes();

      for (final serverData in serverNotes) {
        final serverId = serverData['id'] as String;
        final serverUpdatedAt =
            DateTime.parse(serverData['updatedAt'] as String);
        final localData = notesBox.get(serverId);

        if (localData == null) {
          final hasPendingDelete = queueBox.values.any((v) {
            try {
              final op = SyncOperation.fromJson(Map<String, dynamic>.from(v));
              return op.noteId == serverId &&
                  op.operationType == OperationType.delete;
            } catch (_) {
              return false;
            }
          });
          if (hasPendingDelete) continue;

          await notesBox.put(
            serverId,
            NoteModel(
              id: serverId,
              title: serverData['title'] as String,
              body: serverData['body'] as String? ?? '',
              updatedAt: serverUpdatedAt,
              syncStatus: SyncStatus.synced,
              lastSyncedAt: DateTime.now(),
            ).toJson(),
          );
        } else {
          final local =
              NoteModel.fromJson(Map<String, dynamic>.from(localData));

          if (local.syncStatus == SyncStatus.synced &&
              serverUpdatedAt.isAfter(local.updatedAt)) {
            await notesBox.put(
              serverId,
              NoteModel(
                id: serverId,
                title: serverData['title'] as String,
                body: serverData['body'] as String? ?? '',
                updatedAt: serverUpdatedAt,
                syncStatus: SyncStatus.synced,
                lastSyncedAt: DateTime.now(),
              ).toJson(),
            );
          }
        }
      }
    } catch (e) {
      _log.e('Pull failed', error: e);
    }
  }
}