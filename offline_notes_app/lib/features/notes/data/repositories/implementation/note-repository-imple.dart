

import 'package:offline_notes_app/features/notes/data/local/note-local-datasources.dart';
import 'package:offline_notes_app/features/notes/data/models/data-sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note-model.dart';
import 'package:offline_notes_app/features/notes/data/repositories/contract/note-respository.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource localDataSource;

  NoteRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<void> addNote(NoteModel note) {
    return localDataSource.addNote(note);
  }

  @override
  Future<void> updateNote(NoteModel note) {
    return localDataSource.updateNote(note);
  }

  @override
  Future<void> deleteNote(String id) {
    return localDataSource.deleteNote(id);
  }

  @override
  Future<List<NoteModel>> getNotes() {
    return localDataSource.getAllNotes();
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() {
    return localDataSource.getPendingOperations();
  }
}