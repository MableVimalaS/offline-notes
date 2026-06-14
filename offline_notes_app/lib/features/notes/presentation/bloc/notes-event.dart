
import 'package:offline_notes_app/features/notes/data/models/note-model.dart';

abstract class NotesEvent {}


class LoadNotes extends NotesEvent {}

class AddNote extends NotesEvent {
  final NoteModel note;

  AddNote(this.note);
}

class UpdateNote extends NotesEvent {
  final NoteModel note;

  UpdateNote(this.note);
}

class DeleteNote extends NotesEvent {
  final String noteId;

  DeleteNote(this.noteId);
}