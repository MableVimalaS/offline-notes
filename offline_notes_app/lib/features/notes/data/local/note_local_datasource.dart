import 'package:offline_notes_app/features/notes/data/models/data_sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';

abstract class NoteLocalDataSource {
  Future<void> addNote(NoteModel note);

  Future<void> updateNote(NoteModel note);

  Future<void> deleteNote(String id);

  Future<List<NoteModel>> getAllNotes();

  Future<List<SyncOperation>> getPendingOperations();
  Future<void> resolveConflict(String noteIds, {required bool keepLocal});
}
