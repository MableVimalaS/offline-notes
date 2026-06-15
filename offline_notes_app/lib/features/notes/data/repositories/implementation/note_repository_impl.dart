import 'package:offline_notes_app/features/notes/data/local/note_local_datasource.dart';
import 'package:offline_notes_app/features/notes/data/models/data_sync.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';
import 'package:offline_notes_app/features/notes/data/repositories/contract/note_repository.dart';

class NoteRepositoryImpl implements NoteRepository {
  const NoteRepositoryImpl({required this.localDataSource});

  final NoteLocalDataSource localDataSource;

  @override
  Future<void> addNote(NoteModel note) => localDataSource.addNote(note);

  @override
  Future<void> updateNote(NoteModel note) => localDataSource.updateNote(note);

  @override
  Future<void> deleteNote(String id) => localDataSource.deleteNote(id);

  @override
  Future<List<NoteModel>> getNotes() => localDataSource.getAllNotes();

  @override
  Future<List<SyncOperation>> getPendingOperations() =>
      localDataSource.getPendingOperations();
}
