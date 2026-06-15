import 'package:logger/logger.dart';
import 'package:offline_notes_app/features/notes/data/models/note_model.dart';

final _log = Logger();

class NoteRemoteDataSource {
  Future<void> createNote(NoteModel note) async {
    await Future.delayed(const Duration(seconds: 1));
    _log.d('Server: Created ${note.id}');
  }

  Future<void> updateNote(NoteModel note) async {
    await Future.delayed(const Duration(seconds: 1));
    _log.d('Server: Updated ${note.id}');
  }

  Future<void> deleteNote(String noteId) async {
    await Future.delayed(const Duration(seconds: 1));
    _log.d('Server: Deleted $noteId');
  }
}
